# frozen_string_literal: true

class EvaluationBase
  EVENEMENT = {
    STOP: 'stop'
  }.freeze

  delegate :session_id, :utilisateur, :situation, :date, to: :premier_evenement

  def initialize(evenements)
    @evenements = evenements
  end

  def compte_nom_evenements(nom)
    @evenements.count { |e| e.nom == nom }
  end

  def temps_total
    @evenements.last.date - @evenements.first.date
  end

  def premier_evenement
    @evenements.first
  end

  def abandon?
    @evenements.last.nom == EVENEMENT[:STOP]
  end
end