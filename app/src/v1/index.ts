import { STRAW_HATS } from "../common/bounties.js";
import { sail } from "../common/ship.js";

// Going Merry: the bounty board is a static list.
sail({
  name: "Going Merry",
  color: "#1d4ed8",
  getBounties: async () => STRAW_HATS,
});
