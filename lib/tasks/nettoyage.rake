# frozen_string_literal: true

namespace :nettoyage do

  def noms_colonnes(mes, colonnes, colonnes_z)
    noms = ""
    noms += "#{mes}: #{colonnes[mes].join("; #{mes}: ")};" unless colonnes[mes].empty?
    noms += "#{mes}: cote_z_#{colonnes_z[mes].join("; #{mes}: cote_z_")};" unless colonnes_z[mes].empty?
    noms
  end

  desc 'Extrait les données pour calcule le taux de bonne réponses Livraison et Objets trouvés pour les psychologues'
  task extrait_questions: :environment do
    Rails.logger.level = :warn

    puts "MES;meta-competence;question;succes"

    # Objet trouves
    sessions_ids_objets_trouves = Partie.joins(:situation).where(situations: {nom_technique: :objets_trouves }).select(:session_id)
    evenements = Evenement.where(nom: :reponse)
      .where("donnees ->> 'metacompetence' = 'numeratie'")
      .where(session_id: sessions_ids_objets_trouves)
    evenements.each do |evt|
      puts "objets_trouves;#{evt.donnees['metacompetence']};#{evt.donnees['question']};#{evt.donnees['succes']}"
    end

    # Livraison
    sessions_ids_livraison = Partie.joins(:situation).where(situations: {nom_technique: :livraison }).select(:session_id)
    questions_numeratie = Question.where(metacompetence: 0).select(:id).map { |q| q.id }
    evenements = Evenement.where(nom: :reponse)
      .where("donnees ->> 'question' in ('#{questions_numeratie.join("','")}')")
      .where(session_id: sessions_ids_livraison)
    evenements.each do |evt|
      question = Question.find(evt.donnees['question'])
      metacompetence = question.metacompetence
      question = question.libelle
      reponse = Choix.find(evt.donnees['reponse'])
      succes = reponse.type_choix == "bon"
      puts "livraison;#{metacompetence};#{question};#{succes}"
    end
  end

  desc 'Extrait les données pour les psychologues'
  task extrait_stats: :environment do
    Rails.logger.level = :warn
    colonnes = {
      'bienvenue' => [],
      'maintenance' => Restitution::Maintenance::METRIQUES.keys,
      'livraison' => Restitution::Livraison::METRIQUES.keys,
      'objets_trouves' => Restitution::ObjetsTrouves::METRIQUES.keys
    }
    colonnes_z = {
      'bienvenue' => [],
      'maintenance' => Restitution::Maintenance::METRIQUES.keys,
      'livraison' => Restitution::Livraison::METRIQUES.keys,
      'objets_trouves' => Restitution::ObjetsTrouves::METRIQUES.keys
    }
    evaluations = Evaluation.joins(campagne: :compte).where(comptes: { role: :organisation })
    puts "Nombre d'évaluation : #{evaluations.count}"
    entete_colonnes = "campagne;nom evalué·e;date creation de la partie;"
    colonnes.keys.each do |mes|
      entete_colonnes += noms_colonnes(mes, colonnes, colonnes_z)
    end
    puts entete_colonnes
    evaluations.each do |e|
      situations = {}
      colonnes.keys.each do |mes|
        situations[mes] = Array.new(colonnes[mes].count + colonnes_z[mes].count, 'vide')
      end

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
