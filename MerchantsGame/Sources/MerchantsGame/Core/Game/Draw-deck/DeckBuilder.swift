public enum DeckBuilder {
    public static func standardDeck<R: RandomSource>(using random: inout R) -> DrawDeck {
        var cards = GoodType.allCases.flatMap { good in
            Array(repeating: GoodsCard(good: good), count: 10)
        }
        random.shuffle(&cards)
        return DrawDeck(cards: cards)
    }
}
