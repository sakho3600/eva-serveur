# frozen_string_literal: true

namespace :nettoyage do
  desc 'Extrait les données pour les psychologues'
  task extrait_stats: :environment do
    Rails.logger.level = :warn
    colonnes = {
      'bienvenue' => [],
      'maintenance' => [],
      'livraison' => [],
      'objets_trouves' => [],
      'inventaire' => [ 'temps_total', 'nombre_ouverture_contenant', 'nombre_essais_validation' ],
      'securite' => Restitution::Securite::METRIQUES.keys,
      'tri' => [ 'temps_total', 'nombre_bien_placees', 'nombre_mal_placees' ],
      'controle' => [ 'nombre_bien_placees', 'nombre_mal_placees', 'nombre_non_triees' ]
    }
    colonnes_z = {
      'bienvenue' => [],
      'maintenance' => ['score_ccf'],
      'livraison' => ['score_numeratie', 'score_ccf', 'score_syntaxe_orthographe'],
      'objets_trouves' => ['score_numeratie', 'score_ccf', 'score_memorisation'],
      'inventaire' => [],
      'securite' => (Restitution::Securite::METRIQUES.map { |nom, metrique| nom if metrique['type'] == :nombre }).compact,
      'tri' => [],
      'controle' => []
    }
    evaluations = Evaluation.joins(campagne: :compte).where(comptes: { role: :organisation })
    puts "Nombre d'évaluation : #{evaluations.count}"
    puts "campagne;nom evalué·e;date creation de la partie;maintenance: score ccf;OT: score numeratie;OT: score ccf;OT: score mémorisation;livraison: score numeratie;livraison: score ccf;livraison: score syntax orthographe;inventaire: #{colonnes['inventaire'].join(";inventaire: ")};securite: #{(colonnes['securite'] + colonnes_z['securite']).join("; securite: ")};tri: #{colonnes['tri'].join(";tri: ")};controle: #{colonnes['controle'].join(";controle: ")};Bienvenue: toutes les colonnes"
    evaluations.each do |e|
      situations = {
        'maintenance' => Array.new(1, 'vide'),
        'livraison' => Array.new(3, 'vide'),
        'objets_trouves' => Array.new(3, 'vide'),
        'inventaire' => Array.new(colonnes['inventaire'].count, 'vide'),
        'securite' => Array.new(colonnes['securite'].count + colonnes_z['securite'].count, 'vide'),
        'tri' => Array.new(colonnes['tri'].count, 'vide'),
        'controle' => Array.new(colonnes['controle'].count, 'vide'),
        'bienvenue' => []
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
        else
          colonnes[partie.situation.nom_technique]&.each do |metrique|
            valeur = partie.metriques[metrique]&.to_s || restitution.send(metrique)&.to_s
            situations[partie.situation.nom_technique] << (valeur || 'vide')
          end
          colonnes_z[partie.situation.nom_technique]&.each do |metrique|
            situations[partie.situation.nom_technique] << (restitution.cote_z_metriques[metrique] || 'vide')
          end
        end
      end
      valeurs_des_parties = situations.keys.map do |situation|
        situations[situation].join('; ')
      end
      puts "#{e.campagne&.libelle};#{e.nom};#{e.created_at};" + valeurs_des_parties.join('; ')
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
