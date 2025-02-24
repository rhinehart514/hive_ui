import LandingPage from "lib/landing_page.dart";   
import SignInPage from "lib/sign_in_page.dart";
import OnboardingPage from "lib/onboarding.dart";
import MainFeed from "lib/main_feed.dart";
import ProfilePage from "lib/profile.dart";
import Messaging from "lib/messaging.dart";
import ClubsOrgs from "lib/clubs_orgs.dart";
import ClubProfile from "lib/club_profile.dart";
import HiveLab from "lib/hive_lab.dart";
import Spaces from "lib/spaces.dart";  

// Define a route type
interface Route {
  path: string;
  render: () => string;
}

// Set up the routes  
const routes: Route[] = [
  { path: "/", render: LandingPage },
  { path: "/sign_in_page", render: SignInPage },
  { path: "/create_account", render: CreateAccountPage },
  { path: "/onboarding", render: OnboardingPage },
  { path: "/main_feed", render: MainFeed },
  { path: "/profile", render: ProfilePage },
  { path: "/messaging", render: Messaging },
  { path: "/clubs_orgs", render: ClubsOrgs },
  { path: "/club_profiles", render: ClubProfile }, // note: dynamic parameters not handled
  { path: "/hivelab", render: HiveLab },
  { path: "/spaces", render: Spaces }
];

// Router function to display the route content in the element with id 'app'
export function router() {
  const hash = window.location.hash.slice(1) || "/";
  const route = routes.find(r => r.path === hash);
  const appDiv = document.getElementById("app");
  if (appDiv) {
    appDiv.innerHTML = route ? route.render() : "<div>404 Not Found</div>";
  }
}

// Set up listeners for hash change and page load
window.addEventListener("hashchange", router);
window.addEventListener("load", router);

// Simple navigation function
export function navigate(path: string) {
  window.location.hash = path;
} 

function CreateAccountPage(): string {
  throw new Error("Function not implemented.");
}
