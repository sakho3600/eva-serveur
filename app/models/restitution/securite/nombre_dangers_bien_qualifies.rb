# frozen_string_literal: true

module Restitution
  class Securite
    class NombreDangersBienQualifies < Restitution::Metriques::Base
      def calcule(evenements_situation, _)
        qualifications_par_dangers = SecuriteHelper.qualifications_par_danger(evenements_situation)
        qualifications_par_dangers.map do |_danger, qualifications|
          qualifications.max_by(&:created_at)
        end.count(&:bonne_reponse?)
      end
    end
  end
end
