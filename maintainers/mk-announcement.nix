{
  apps,
  pkgs,
  lib,
}:

lib.mapAttrs (
  name: app:

  pkgs.writeShellApplication {
    name = "announce-project";
    runtimeInputs = with pkgs; [
      jq
    ];
    text = ''
      set -eux

      APP_URL="https://ngi-nix.github.io/forge/app/${app.name}"
      JITSI_URL="https://jitsi.lassul.us/ngi-nix-office-hours"
      CALENDAR_URL="https://calendar.google.com/calendar/u/0/embed?src=b9o52fobqjak8oq8lfkhg3t0qg@group.calendar.google.com"
      MATRIX_URL="https://matrix.to/#/#ngipkgs:matrix.org"
      TEAM_URL="https://nixos.org/community/teams/ngi"
      NIX_URL="https://nix.dev"
      SURVEY_URL="https://nixos-foundation.notion.site/35759d49e1be81edb478e3aade9f8e95?pvs=105"
      NAME="${app.displayName}"
      SUMMARY=$(jq -rn --argjson description '${lib.strings.toJSON app.description}' \
      '
        $description
        | rtrimstr(".") as $s
        | ($s[0:1] | ascii_downcase) + $s[1:]
      ')
      HOMEPAGE_URL=$(jq -rn --argjson links '${lib.strings.toJSON app.links}' \
      '
        if $links.website != null then $links.website.url
        elif $links.source != null then $links.source.url
        else "<ADD_HOMEPAGE_URL>"
        end
      ')
      GRANT_STR=$(jq -rn --argjson ngi '${lib.strings.toJSON app.ngi}' \
      '
        [
          $ngi.grants
          | to_entries[]
          | select(.value | length > 0)
          | .key
        ]
        | join(", ")
      ')

      cat <<EOF
      # Discourse post
      \`\`\`text
      ${lib.readFile ./discourse.md}\`\`\`
      ---

      # Email to NLnet
      \`\`\`text
      ${lib.readFile ./nlnet.txt}\`\`\`
      ---

      # Email to project author
      \`\`\`text
      ${lib.readFile ./project-author.txt}\`\`\`
      EOF
    '';
  }
) apps
