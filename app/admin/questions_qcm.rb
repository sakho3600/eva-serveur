# frozen_string_literal: true

ActiveAdmin.register QuestionQcm do
  menu parent: 'Questions'

  filter :intitule

  permit_params :libelle, :intitule, :description, :illustration, :metacompetence,
                choix_attributes: %i[id intitule type_choix _destroy]

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :libelle
      f.input :intitule
      f.input :metacompetence
      f.input :description
      f.input :illustration, as: :file
      f.has_many :choix, allow_destroy: ->(choix) { can? :destroy, choix } do |c|
        c.input :id, as: :hidden
        c.input :intitule
        c.input :type_choix
      end
    end
    f.actions
  end

  index do
    selectable_column
    column :id
    column :libelle
    column :intitule
    column :metacompetence
    column :description
    column :created_at
    column :updated_at
    actions
  end

  show do
    render partial: 'show'
  end
end
