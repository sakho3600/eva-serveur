# frozen_string_literal: true

namespace :nettoyage do
  desc 'Extrait les données pour les psychologues'
  task extrait_stats: :environment do
    Rails.logger.level = :warn
    puts "campagne;nom evalué·e;date creation de la partie;maintenance: score ccf;OT: score numeratie;OT: score ccf;OT: score mémorisation;livraison: score numeratie;livraison: score ccf;livraison: score syntax orthographe;Bienvenue: toutes les colonnes"
    Evaluation.all.each do |e|
      next if e.campagne&.libelle&.downcase&.include?('test') ||
        e.campagne&.code&.downcase&.include?('test') ||
        e.campagne&.code&.downcase&.include?('demo')

      situations = {
        'bienvenue' => [],
        'maintenance' => Array.new(1, 'vide'),
        'livraison' => Array.new(3, 'vide'),
        'objets_trouves' => Array.new(3, 'vide')
      }
      Partie.where(evaluation: e).order(:created_at).each do |partie|
        restitution = FabriqueRestitution.instancie partie.id
        next unless restitution.termine?

        situations[partie.situation.nom_technique] = []
        case partie.situation.nom_technique
        when 'bienvenue'
          restitution.questions_et_reponses.each do |question_et_reponse|
            reponse = question_et_reponse[:reponse]
            question = question_et_reponse[:question]
            situations[partie.situation.nom_technique] << question.libelle
            situations[partie.situation.nom_technique] << reponse.intitule
          end
        when 'maintenance'
          ['score_vocabulaire'].each do |metrique|
            situations[partie.situation.nom_technique] << (partie.cote_z_metriques[metrique] || 'vide')
          end
        when 'livraison'
          ['score_numeratie', 'score_ccf', 'score_syntaxe_orthographe'].each do |metrique|
            situations[partie.situation.nom_technique] << (partie.cote_z_metriques[metrique] || 'vide')
          end
        when 'objets_trouves'
          ['score_numeratie', 'score_ccf', 'score_memorisation'].each do |metrique|
            situations[partie.situation.nom_technique] << (partie.cote_z_metriques[metrique] || 'vide')
          end
        end
      end
      cellues = ['maintenance', 'objets_trouves', 'livraison', 'bienvenue'].map do |situation|
        situations[situation].join('; ')
      end
      puts "#{e.campagne&.libelle};#{e.nom};#{e.created_at};" + cellues.join('; ')
    end
  end

  desc 'Ajoute les événements terminés'
  task ajoute_evenements_termines: :environment do
    Partie.find_each do |partie|
      evenements = Evenement.where(partie: partie)
      next if evenements.where(nom: 'finSituation').exists?

      restitution = FabriqueRestitution.instancie partie.id
      next unless restitution.termine?

      dernier_evenement = evenements.order(:date).last
      Evenement.create! partie: partie, nom: 'finSituation', date: dernier_evenement.date + 0.001
    end
  end

  desc 'Supprime les événements après la fin'
  task supprime_evenements_apres_la_fin: :environment do
    logger = RakeLogger.logger
    logger.info 'Evenements effacées:'
    Partie.find_each do |partie|
      date_fin = nil
      evenements = Evenement.where(partie: partie).order(:date)
      evenements_jusqua_fin = evenements.take_while do |evenement|
        date_fin ||= evenement.date if evenement.nom == 'finSituation'

        date_fin.nil? || evenement.date == date_fin
      end

      evenements_apres_fin = evenements - evenements_jusqua_fin
      evenements_apres_fin.each { |evenement| logger.info evenement }
      Evenement.where(id: evenements_apres_fin.collect(&:id)).destroy_all
    end
  end
end

class RakeLogger
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end
