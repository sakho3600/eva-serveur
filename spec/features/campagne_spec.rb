# frozen_string_literal: true

require 'rails_helper'

describe 'Admin - Campagne', type: :feature do
  let!(:compte_connecte) { se_connecter_comme_organisation }
  let!(:ma_campagne) do
    create :campagne, libelle: 'Amiens 18 juin', code: 'A5RC8', compte: Compte.first
  end
  let(:compte_organisation) { create :compte_organisation, email: 'orga@eva.fr' }
  let!(:campagne) do
    create :campagne, libelle: 'Rouen 30 mars', code: 'A5ROUEN', compte: compte_organisation
  end
  let!(:evaluation) { create :evaluation, campagne: campagne }
  let!(:evaluation_organisation) { create :evaluation, campagne: ma_campagne }

  describe 'index' do
    context 'en organisation' do
      before { visit admin_campagnes_path }

      it do
        expect(page).to have_content 'Amiens 18 juin'
        expect(page).to have_content 'A5RC8'
        expect(page).to_not have_content 'Rouen 30 mars'
      end

      it 'ne permet pas de filtrer par compte' do
        within '.panel_contents' do
          expect(page).to_not have_content 'Compte'
        end
      end
    end

    context 'en administrateur' do
      before do
        compte_connecte.update(role: 'administrateur')
        visit admin_campagnes_path
      end

      it 'permet de filtrer par compte' do
        within '.panel_contents' do
          expect(page).to have_content 'Compte'
        end
      end
    end

    context 'quelque soit le rôle' do
      before { visit admin_campagnes_path }

      it "affiche le nombre d'évaluation par campagne" do
        within('#index_table_campagnes') do
          expect(page).to have_content "Nombre d'évaluations"
        end
        within('td.col-nombre_evaluations') do
          expect(page).to have_content '1'
        end
      end
    end
  end

  describe 'création' do
    let!(:questionnaire) { create :questionnaire, libelle: 'Mon QCM' }

    context 'en organisation' do
      before do
        visit new_admin_campagne_path
        fill_in :campagne_libelle, with: 'Belfort, pack demandeur'
      end

      context 'génère un code si on en saisit pas' do
        before do
          fill_in :campagne_code, with: ''
          select 'Mon QCM'
        end

        it do
          expect { click_on 'Créer' }.to(change { Campagne.count })
          expect(Campagne.last.code).to be_present
          expect(Campagne.last.compte).to eq compte_connecte
          expect(page).to have_content 'Mon QCM'
        end

        context 'conserve le code saisi si précisé' do
          before { fill_in :campagne_code, with: 'EUROCKS' }
          it do
            expect { click_on 'Créer' }.to(change { Campagne.count })
            expect(Campagne.last.code).to eq 'EUROCKS'
          end
        end
      end
    end

    context 'en administrateur' do
      before do
        Compte.first.update(role: 'administrateur')
        visit new_admin_campagne_path
        fill_in :campagne_libelle, with: 'Belfort, pack demandeur'
        fill_in :campagne_code, with: ''
        select 'Mon QCM'
        select 'orga@eva.fr'
      end

      it do
        expect { click_on 'Créer' }.to(change { Campagne.count })
        expect(Campagne.last.compte).to eq compte_organisation
      end
    end
  end

  describe 'nouveau partenaire', focus: true do
    context 'en admin' do
      let(:situation) { create :situation_inventaire }
      before do
        Compte.first.update(role: 'administrateur')
        visit nouveau_partenaire_admin_campagnes_path
        fill_in :campagne_libelle, with: 'Belfort, pack demandeur'
        fill_in :campagne_code, with: 'belfortPack'

        fill_in :compte_email, with: 'jeanmarc@nouvelle.structure.fr'
        fill_in :compte_password, with: 'billyjoel'
        fill_in :compte_password_confirmation, with: 'billyjoel'

        fill_in :structure_nom, with: 'Nouvelle Structure'
        fill_in :structure_code_postal, with: '06000'
      end
      it do
        expect do
          click_on 'Créer'
        end.to change(Structure, :count)
          .and change(Compte, :count)
          .and change(Campagne, :count)
      end
    end
  end

  describe 'show' do
    context 'en admin' do
      let(:situation) { create :situation_inventaire }
      before do
        Compte.first.update(role: 'administrateur')
        campagne.situations_configurations.create! situation: situation
        visit admin_campagne_path campagne
      end
      it { expect(page).to have_content 'Inventaire' }
    end

    context 'en organisation' do
      before { visit admin_campagne_path(ma_campagne) }
      it do
        expect(page).to_not have_content 'les stats'
        expect(page).to_not have_content 'les événements'
      end
    end
  end
end
