# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

describe Compte do
  it { should validate_inclusion_of(:role).in_array(%w[administrateur organisation]) }

  describe 'Gestion des droits' do
    subject(:ability) { Ability.new(compte) }

    context 'Compte administrateur' do
      let(:compte) { build :compte, role: 'administrateur' }

      it { is_expected.to be_able_to(:manage, :all) }
    end

    context 'Compte organisation' do
      let(:compte) { build :compte, role: 'organisation' }

      it { is_expected.to_not be_able_to(:manage, Compte.new) }
    end
  end
end
