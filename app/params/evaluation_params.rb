# frozen_string_literal: true

class EvaluationParams
  class << self
    def from(params)
      permitted = params.permit(
        :nom,
        :code_campagne,
        :email,
        :telephone
      )
      relie_campagne!(permitted)
      permitted
    end

    private

    def relie_campagne!(params)
      return if params['code_campagne'].blank?

      code_campagne = params.delete('code_campagne')
      campagne = Campagne.find_by code: code_campagne
      params['campagne'] = campagne
    end
  end
end
