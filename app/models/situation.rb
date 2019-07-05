# frozen_string_literal: true

class Situation < ApplicationRecord
  validates :libelle, presence: true
  validates :nom_technique, presence: true, uniqueness: true
end