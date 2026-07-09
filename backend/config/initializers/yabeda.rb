Yabeda.configure do
  group :paredao do
    counter :votes_total,
            comment: 'Total de votos registrados com sucesso, por evento e participante.',
            tags: %i[event participant]
  end
end
