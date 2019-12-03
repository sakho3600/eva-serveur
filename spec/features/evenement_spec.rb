# frozen_string_literal: true

require 'rails_helper'

describe 'Admin - Evenement', type: :feature do
  let(:chemin) { "#{Rails.root}/spec/support/evenement/donnees.json" }
  let(:donnees) { JSON.parse(File.read(chemin)) }
  let(:situation_inventaire) { create :situation_inventaire, libelle: 'Inventaire' }
  let(:evaluation) { create :evaluation }
  let!(:partie) do
    create :partie,
           situation: situation_inventaire,
           evaluation: evaluation,
           evenements: [evenement],
           session_id: '1898098HJk8902'
  end

  let(:evenement) do
    build :evenement, nom: 'ouvertureContenant',
                      donnees: donnees,
                      session_id: '1898098HJk8902'
  end

  before do
    se_connecter_comme_administrateur
    visit admin_evenements_path
  end

  it 'Affiche les événements' do
    expect(page).to have_content 'ouvertureContenant'
    expect(page).to have_content donnees['type']
    expect(page).to have_content '1898098HJk8902'
  end

  it "Empêche l'administrateur de créer/modifier un événement" do
    expect(page).to_not have_content 'Créer'
    expect(page).to_not have_content 'Modifier'
  end
end
