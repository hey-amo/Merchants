// Colour reference
const COLOURS = ['Red', 'Yellow', 'Green', 'Blue', 'White', 'Purple'];

// Create deck: 10 cards of each colour
function createDeck() {
    const deck = [];
    COLOURS.forEach(colour => {
        for (let i = 0; i < 10; i++) {
            deck.push({ colour });
        }
    });
    return deck;
}

const deck = createDeck();

// Create cubes: 5 of each colour
function createCubes() {
    const cubes = {};
    COLOURS.forEach(colour => {
        cubes[colour] = 5;
    });
    return cubes;
}

const cubes = createCubes();

// Example: log deck and cubes
console.log('Deck:', deck);
console.log('Cubes:', cubes);