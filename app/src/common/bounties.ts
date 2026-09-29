export interface Bounty {
  name: string;
  epithet: string;
  berries: number;
  emoji: string; // fallback when the portrait can't load
  image: string; // file under public/crew/ (see CREDITS.md)
}

// Straw Hat crew wanted posters (demo data).
export const STRAW_HATS: Bounty[] = [
  { name: "Monkey D. Luffy", epithet: "Straw Hat", berries: 3_000_000_000, emoji: "👒", image: "monkey-d-luffy.png" },
  { name: "Roronoa Zoro", epithet: "Pirate Hunter", berries: 1_111_000_000, emoji: "⚔️", image: "roronoa-zoro.png" },
  { name: "Jinbe", epithet: "Knight of the Sea", berries: 1_100_000_000, emoji: "🐋", image: "jinbe.png" },
  { name: "Sanji", epithet: "Black Leg", berries: 1_032_000_000, emoji: "🍳", image: "sanji.png" },
  { name: "Nico Robin", epithet: "Devil Child", berries: 930_000_000, emoji: "📚", image: "nico-robin.png" },
  { name: "Usopp", epithet: "God", berries: 500_000_000, emoji: "🎯", image: "usopp.png" },
  { name: "Franky", epithet: "Iron Man", berries: 394_000_000, emoji: "🤖", image: "franky.png" },
  { name: "Brook", epithet: "Soul King", berries: 383_000_000, emoji: "🎻", image: "brook.png" },
  { name: "Nami", epithet: "Cat Burglar", berries: 366_000_000, emoji: "🍊", image: "nami.png" },
  { name: "Tony Tony Chopper", epithet: "Cotton Candy Lover", berries: 1_000, emoji: "🦌", image: "tony-tony-chopper.png" },
];
