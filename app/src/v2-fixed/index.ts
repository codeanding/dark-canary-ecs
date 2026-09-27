import { STRAW_HATS } from "../common/bounties.js";
import { sail } from "../common/ship.js";
import { withDenDenMushi } from "./den-den-mushi.js";

// Thousand Sunny: new feature — every bounty board read calls Marine HQ over a Den Den Mushi
// to get fresh bounties.
sail({
  name: "Thousand Sunny",
  color: "#15803d",
  getBounties: () => withDenDenMushi(async () => STRAW_HATS),
});
