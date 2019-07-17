# frozen_string_literal: true

ActiveAdmin.register Campagne do
  permit_params :libelle, :code, :questionnaire_id,
                situations_configurations_attributes: %i[id situation_id _destroy]

  show do
    render partial: 'show'
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :libelle
      f.input :code
      f.input :questionnaire
      f.has_many :situations_configurations, allow_destroy: true do |c|
        c.input :id, as: :hidden
        c.input :situation
      end
    end
    f.actions
  end
end
