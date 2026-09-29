export interface Bounty {
  name: string;
  epithet: string;
  berries: number;
  emoji: string; // stands in for a portrait: no official art in this repo
}

// Straw Hat crew wanted posters (demo data).
export const STRAW_HATS: Bounty[] = [
  { name: "Monkey D. Luffy", epithet: "Straw Hat", berries: 3_000_000_000, emoji: "👒" },
  { name: "Roronoa Zoro", epithet: "Pirate Hunter", berries: 1_111_000_000, emoji: "⚔️" },
  { name: "Jinbe", epithet: "Knight of the Sea", berries: 1_100_000_000, emoji: "🐋" },
  { name: "Sanji", epithet: "Black Leg", berries: 1_032_000_000, emoji: "🍳" },
  { name: "Nico Robin", epithet: "Devil Child", berries: 930_000_000, emoji: "📚" },
  { name: "Usopp", epithet: "God", berries: 500_000_000, emoji: "🎯" },
  { name: "Franky", epithet: "Iron Man", berries: 394_000_000, emoji: "🤖" },
  { name: "Brook", epithet: "Soul King", berries: 383_000_000, emoji: "🎻" },
  { name: "Nami", epithet: "Cat Burglar", berries: 366_000_000, emoji: "🍊" },
  { name: "Tony Tony Chopper", epithet: "Cotton Candy Lover", berries: 1_000, emoji: "🦌" },
];
