##
# classe permettant de gérer les écarts entre 2 dates
# exprimés en années, mois et jour
class Madate

  # constructeur
  def initialize(jour, mois, annee)
    @jour = jour
    @mois = mois
    @annee = annee
  end

  # retourne un texte vide si 0
  # ajoute un 's' au texte si plusieurs
  def ecart_texte(valeur, texte)
    return '' if valeur <= 0
    return valeur.to_s + ' ' + texte if valeur == 1 || texte.end_with?('s')
    valeur.to_s + ' ' + texte + 's'
  end

  # calcule l'écart entre la date et la date donnée
  # en années, mois et jours
  def ecart(jour, mois, annee)
    if jour < @jour
      case mois
        when 1, 2, 4, 6, 8, 9, 11
          jour += 31
        when 5, 7, 10, 12
          jour += 30
        else
          jour += (annee % 4).zero? ? 29 : 28
      end
      mois -= 1
    end
    if mois < @mois
      mois += 12
      annee -= 1
    end
    return 'Je suis déjà parti !' if annee < @annee
    res = ecart_texte(annee - @annee, 'année') + ' ' +
      ecart_texte(mois - @mois, 'mois') + ' ' +
      ecart_texte(jour - @jour, 'jour')
    res.gsub(/^ +/, "").gsub(/ +$/, "").gsub(/  /, " ")
  end
end
