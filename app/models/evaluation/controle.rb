# frozen_string_literal: true

module Evaluation
  class Controle < Base
    PIECES_TOTAL = 60

    EVENEMENT = {
      PIECE_BIEN_PLACEE: 'pieceBienPlacee',
      PIECE_MAL_PLACEE: 'pieceMalPlacee',
      PIECE_RATEE: 'pieceRatee'
    }.freeze

    def termine?
      evenements_pieces.count == PIECES_TOTAL
    end

    def nombre_bien_placees
      compte_nom_evenements EVENEMENT[:PIECE_BIEN_PLACEE]
    end

    def nombre_mal_placees
      compte_nom_evenements EVENEMENT[:PIECE_MAL_PLACEE]
    end

    def nombre_ratees
      compte_nom_evenements EVENEMENT[:PIECE_RATEE]
    end

    def noms_evenements_pieces
      EVENEMENT.slice(:PIECE_BIEN_PLACEE, :PIECE_MAL_PLACEE, :PIECE_RATEE).values
    end

    def evenements_pieces
      @evenements.find_all { |e| noms_evenements_pieces.include?(e.nom) }
    end

    def enleve_premiers_evenements_pieces(nombre)
      compteur = 0
      nouveaux_evenements = evenements.reject do |evenement|
        noms_evenements_pieces.include?(evenement.nom) && (compteur += 1) <= nombre
      end
      self.class.new(nouveaux_evenements)
    end

    def competences
      {
        ::Competence::RAPIDITE => Controle::Rapidite,
        ::Competence::COMPARAISON_TRI => Controle::ComparaisonTri,
        ::Competence::ATTENTION_CONCENTRATION => Controle::AttentionConcentration
      }.each_with_object({}) do |(competence, classe), resultat|
        resultat[competence] = classe.new(self).niveau
      end
    end
  end
end