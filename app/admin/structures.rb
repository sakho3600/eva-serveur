# frozen_string_literal: true

ActiveAdmin.register Structure do
  permit_params :nom, :code_postal

  index do
    column :nom
    column :code_postal
    column :nombre_evaluations do |structure|
      Evaluation.joins(campagne: :compte).where('comptes.structure_id' => structure).count
    end
    column :created_at
    actions
  end

  filter :nom
  filter :code_postal
  filter :created_at

  form do |structure|
    structure.semantic_errors
    structure.inputs do
      structure.input :nom
      structure.input :code_postal
    end
    structure.inputs 'Utilisateur principal', for: :compte do |compte|
      compte.input :email
      #      compte.input :role, 'organisation'
      compte.input :structure
      compte.input :password
      compte.input :password_confirmation
    end
    structure.inputs 'Première campagne', for: :campagne do |campagne|
      #      campagne.input :compte
      campagne.input :libelle
      campagne.input :code
    end
    structure.actions
  end
end
