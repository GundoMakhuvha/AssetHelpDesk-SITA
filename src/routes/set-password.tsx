import { ORG, ORG_TITLE } from "@/lib/org-config";
import { createFileRoute } from "@tanstack/react-router";
import { SetPasswordPage } from "@/features/auth/SetPasswordPage";

export const Route = createFileRoute("/set-password")({
  component: SetPasswordPage,
  head: () => ({
    meta: [
      { title: `Create your password | ${ORG.helpdeskName}` },
      {
        name: "description",
        content:
          `Set your own password to access the ${ORG_TITLE} system.`,
      },
      { property: "og:title", content: `Create your password | ${ORG.helpdeskName}` },
      {
        property: "og:description",
        content: `Set your own password for the ${ORG.helpdeskName}.`,
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
});
