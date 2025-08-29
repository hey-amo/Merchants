/* Merchants2.js */

// Game Constants
const COLORS = ['white', 'blue', 'red', 'green', 'yellow', 'brown'];
const SPECIAL_CARDS = {
    ship: { cost: 10, count: 14, name: 'Ship', description: 'Hold one more cube' },
    office: { cost: 10, count: 2, name: 'Office', description: '2 extra coins per delivery' },
    warehouse: { cost: 10, count: 2, name: 'Warehouse', description: 'Hand size +2' },
    forklift: { cost: 10, count: 2, name: 'Forklift', description: 'Draw +1 card' },
    crane: { cost: 10, count: 2, name: 'Crane', description: 'Exchange +1 cube' }
};
const MAX_HAND_SIZE = 8;
const STARTING_COINS = 5;
const STARTING_HAND_SIZE = 3;