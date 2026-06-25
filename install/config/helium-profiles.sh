# maitri: pre-create two Helium profiles on first install — "Work" and "Personal".
# EXPERIMENTAL: assumes a recent Chromium profile schema. Does nothing if Helium has
# already run, so it never clobbers existing profiles. No theme/color is forced —
# Helium uses its own default appearance.
#
# Helium's Linux user-data dir is ~/.config/net.imput.helium (set in helium-linux's
# change-chromium-branding.patch: data_dir_basename = "net.imput.helium"). Official
# release builds get no channel suffix; only non-official "dev" builds append ".dev".
#
# Note: Chromium only supports its built-in illustration avatars (or a Google-account
# photo) for local profiles — a custom image (the brand heart) can't be set this way.

helium_dir="$HOME/.config/net.imput.helium"

if [[ ! -e "$helium_dir/Local State" ]]; then
  python3 - "$helium_dir" <<'PY'
import json, os, sys
d = sys.argv[1]

# Custom profile directory names. Chromium identifies profiles by their directory key
# as recorded in Local State, so naming the dirs "work"/"personal" (instead of the
# stock "Default"/"Profile 1") works as long as every reference below stays consistent.
for sub in ("work", "personal"):
    os.makedirs(os.path.join(d, sub), exist_ok=True)

local_state = {
    "profile": {
        "info_cache": {
            "work":     {"name": "Work", "is_using_default_name": False,
                         "avatar_icon": "chrome://theme/IDR_PROFILE_AVATAR_26"},
            "personal": {"name": "Personal", "is_using_default_name": False,
                         "avatar_icon": "chrome://theme/IDR_PROFILE_AVATAR_30"},
        },
        "profiles_order": ["work", "personal"],
        "last_used": "work",
        "last_active_profiles": ["work"],
    }
}
json.dump(local_state, open(os.path.join(d, "Local State"), "w"), indent=2)

def prefs(name):
    return {
        "profile": {"name": name},
        "extensions": {
            "theme": {"id": ""},
        },
        # Helium-specific defaults: skip the first-run onboarding and pre-consent to
        # Helium's services so features like bangs and uBlock asset updates work out of
        # the box. Keys verified against the installed helium binary's pref_names; the
        # user can change all of this later.
        "helium": {
            "completed_onboarding": True,
            "services": {
                "enabled": True,
                "user_consented": True,
                "ext_proxy": True,
                "bangs": True,
                "browser_updates": False,   # maitri updates Helium via AUR/pacman, not in-browser
                "spellcheck_files": True,
                "ublock_assets": True,
                "disable_schema_alerts": False,
                "schema_version": 1,
            },
        },
        # Vertical tabs are Helium's default layout; lock the strip width/collapse state.
        "vertical_tabs": {"collapsed_state": False, "uncollapsed_width": 200},
        # Default to Google search (changeable by the user). prepopulate_id 1 binds it to
        # Google's built-in engine definition.
        "default_search_provider_data": {
            "template_url_data": {
                "short_name": "Google",
                "keyword": "google.com",
                "url": "https://www.google.com/search?q={searchTerms}",
                "suggestions_url": "https://www.google.com/complete/search?output=chrome&q={searchTerms}",
                "favicon_url": "https://www.google.com/favicon.ico",
                "prepopulate_id": 1,
                "is_active": 1,
                "safe_for_autoreplace": True,
            },
        },
        # Privacy hardening: disable Privacy Sandbox (Topics, FLEDGE, ad measurement) and
        # First-Party Sets.
        "privacy_sandbox": {
            "first_party_sets_enabled": False,
            "m1": {"ad_measurement_enabled": False, "fledge_enabled": False, "topics_enabled": False},
        },
    }

json.dump(prefs("Work"), open(os.path.join(d, "work", "Preferences"), "w"), indent=2)
json.dump(prefs("Personal"), open(os.path.join(d, "personal", "Preferences"), "w"), indent=2)
print("maitri: seeded Helium profiles — Work + Personal")
PY
fi
