# frozen_string_literal: true

ActiveAdmin.register Campagne do
  config.batch_actions = false
  permit_params :libelle, :code, :questionnaire_id, :compte,
                :compte_id, :affiche_competences_fortes,
                compte_attributes: {},
                situations_configurations_attributes: %i[id situation_id _destroy]

  filter :compte, if: proc { can? :manage, Compte }
  filter :situations
  filter :questionnaire
  filter :created_at

  includes :compte

  index do
    selectable_column
    column :libelle
    column :code
    column :nombre_evaluations
    column :compte if can?(:manage, Compte)
    column :created_at
    actions
  end

  show do
    render partial: 'show'
  end

  collection_action :nouveau_partenaire do
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs do
      f.input :libelle
      f.input :code
      f.input :affiche_competences_fortes
      f.input :questionnaire
      f.has_many :situations_configurations, allow_destroy: true do |c|
        c.input :id, as: :hidden
        c.input :situation
      end
    end
    f.inputs 'Compte utilisateur' do
      f.input :compte if can?(:manage, Compte)
      f.inputs 'Nouveau compte', for: [:compte_attributes, f.object.compte || Compte.new] do |compte|
        compte.input :email
        compte.input :role, as: :select, collection: %w[organisation]
        compte.input :structure
        compte.input :password
        compte.input :password_confirmation
      end
    end
    f.actions
  end

  controller do
    def create
      if(params[:campagne][:compte_attributes].blank? &&
          params[:campagne][:compte_id].blank?)
        params[:campagne][:compte_id] = current_compte.id
      end
      create!
    end
  end
end
