# frozen_string_literal: true

require 'rails_helper'

describe 'Admin - Restitution', type: :feature do
  before { se_connecter_comme_administrateur }

  scenario 'rapport de la situation controle' do
    evenement = create :evenement_piece_bien_placee, situation: 'controle',
                                                     session_id: 'session_controle'
    create :evenement_piece_mal_placee, situation: 'controle', session_id: 'session_controle'
    create :evenement_piece_mal_placee, situation: 'controle', session_id: 'session_controle'

    visit admin_restitution_path(evenement)
    expect(page).to have_content('Pièces Bien Placées 1')
    expect(page).to have_content('Pièces Mal Placées 2')
    expect(page).to have_content('Pièces Non Triées 0')
  end

  scenario 'rapport de la situation inventaire' do
    evenement = create :evenement_saisie_inventaire, :echec, session_id: 'session_inventaire'
    visit admin_restitution_path(evenement)
    expect(page).to have_content('Échec')
  end
end