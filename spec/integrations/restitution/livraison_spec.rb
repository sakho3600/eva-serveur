# frozen_string_literal: true

require 'rails_helper'

describe Restitution::Livraison, type: :integration do
  context 'Calcule le score de deux parties et attend deux résultats différents' do
    let(:situation) { create :situation_livraison }

    let(:partie1) { create :partie, situation: situation, session_id: 'id1' }
    let(:partie2) { create :partie, situation: situation, session_id: 'id2' }
    let(:restitution1) { FabriqueRestitution.instancie partie1.id }
    let(:restitution2) { FabriqueRestitution.instancie partie2.id }

    let(:bon_choix) { create :choix, :bon }
    let(:question_numeratie) do
      create :question_qcm, metacompetence: :numeratie, choix: [bon_choix]
    end

    before do
      create(:evenement_demarrage,
             partie: partie1,
             date: Time.local(2019, 10, 9, 10, 1, 20))
      create(:evenement_affichage_question_qcm,
             partie: partie1,
             donnees: { question: question_numeratie.id },
             date: Time.local(2019, 10, 9, 10, 1, 21))
      create(:evenement_reponse,
             partie: partie1,
             donnees: { question: question_numeratie.id, reponse: bon_choix.id },
             date: Time.local(2019, 10, 9, 10, 1, 22))
    end

    it do
      expect(restitution1.score_numeratie).to_not eq(restitution2.score_numeratie)
    end
  end
end
