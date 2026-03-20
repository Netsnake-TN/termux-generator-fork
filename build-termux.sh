#!/bin/bash
set -e -u -o pipefail

cd "$(realpath "$(dirname "$0")")"

TERMUX_GENERATOR_HOME="$(pwd)"
TERMUX_APP__PACKAGE_NAME="com.termux"
TERMUX_APP_TYPE="f-droid"
DO_NOT_CLEAN=""
TERMUX_GENERATOR_PLUGIN=""
ADDITIONAL_PACKAGES="xkeyboard-config"
BOOTSTRAP_ARCHITECTURES=""
DISABLE_BOOTSTRAP_SECOND_STAGE=""
ENABLE_SSH_SERVER=""
DEFAULT_PASSWORD="changeme"
DISABLE_BOOTSTRAP=""
DISABLE_TERMINAL=""
DISABLE_TASKER=""
DISABLE_FLOAT=""
DISABLE_WIDGET=""
DISABLE_API=""
DISABLE_BOOT=""
DISABLE_STYLING=""
DISABLE_GUI=""
DISABLE_X11=""

source "$TERMUX_GENERATOR_HOME/scripts/termux_generator_utils.sh"
source "$TERMUX_GENERATOR_HOME/scripts/termux_generator_steps.sh"

show_usage() {
    echo
    echo "Usage: build-termux.sh [options]"
    echo
    echo "Generate Termux application."
    echo
    echo "Options:"
    echo " -h, --help                       Show this help."
    echo " -a, --add PKG_LIST               Include additional packages in bootstrap archive."
    echo " -n, --name APP_NAME              Specify package name."
    echo " -t, --type APP_TYPE              Build type [f-droid, play-store]. Defaults to f-droid."
    echo " --architectures ARCH_LIST        Bootstrap architectures (comma-separated)."
    echo " -p, --plugin PLUGIN              Apply plugin from plugins folder."
    echo " --disable-bootstrap-second-stage Disable bootstrap second stage (f-droid only)."
    echo " --enable-ssh-server              Bundle SSH server with default password 'changeme'."
    echo " --disable-bootstrap              Skip building bootstraps."
    echo " --disable-terminal               Skip building Terminal app."
    echo " --disable-tasker                 Skip Termux:Tasker (f-droid only)."
    echo " --disable-float                  Skip Termux:Float (f-droid only)."
    echo " --disable-widget                 Skip Termux:Widget (f-droid only)."
    echo " --disable-api                    Skip Termux:API (f-droid only)."
    echo " --disable-boot                   Skip Termux:Boot (f-droid only)."
    echo " --disable-styling                Skip Termux:Styling (f-droid only)."
    echo " --disable-gui                    Skip Termux:GUI (f-droid only)."
    echo " --disable-x11                    Skip Termux:X11."
    echo " -d, --dirty                      Build without cleaning previous artifacts."
    echo
}

while (($# > 0)); do
    case "$1" in
        -d|--dirty)
            DO_NOT_CLEAN=1
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -a|--add)
            if [ $# -gt 1 ] && [ -n "$2" ] && [[ $2 != -* ]]; then
                ADDITIONAL_PACKAGES+=",$2"
                shift 1
            else
                echo "[!] Option '--add' requires an argument."
                show_usage
                exit 1
            fi
            ;;
        -n|--name)
            if [ $# -gt 1 ] && [ -n "$2" ] && [[ $2 != -* ]]; then
                TERMUX_APP__PACKAGE_NAME="$2"
                shift 1
            else
                echo "[!] Option '--name' requires an argument."
                show_usage
                exit 1
            fi
            ;;
        -t|--type)
            if [ $# -gt 1 ] && [ -n "$2" ] && [[ $2 != -* ]]; then
                case "$2" in
                    f-droid) TERMUX_APP_TYPE="$2" ;;
                    play-store) TERMUX_APP_TYPE="$2" ;;
                    *)
                        echo "[!] Unsupported app type '$2'. Choose one of: [f-droid, play-store]."
                        show_usage
                        exit 1
                        ;;
                esac
                shift 1
            else
                echo "[!] Option '--type' requires an argument."
                show_usage
                exit 1
            fi
            ;;
        --architectures)
            if [ $# -gt 1 ] && [ -n "$2" ] && [[ $2 != -* ]]; then
                BOOTSTRAP_ARCHITECTURES="$2"
                shift 1
            else
                echo "[!] Option '--architectures' requires an argument."
                show_usage
                exit 1
            fi
            ;;
        -p|--plugin)
            if [ $# -gt 1 ] && [ -n "$2" ] && [[ $2 != -* ]]; then
                TERMUX_GENERATOR_PLUGIN="$2"
                shift 1
            else
                echo "[!] Option '--plugin' requires an argument."
                show_usage
                exit 1
            fi
            ;;
        --disable-bootstrap-second-stage)
            DISABLE_BOOTSTRAP_SECOND_STAGE=1
            ;;
        --enable-ssh-server)
            ENABLE_SSH_SERVER=1
            ;;
        --disable-bootstrap)
            DISABLE_BOOTSTRAP=1
            ;;
        --disable-terminal)
            DISABLE_TERMINAL=1
            ;;
        --disable-tasker)
            DISABLE_TASKER=1
            ;;
        --disable-float)
            DISABLE_FLOAT=1
            ;;
        --disable-widget)
            DISABLE_WIDGET=1
            ;;
        --disable-api)
            DISABLE_API=1
            ;;
        --disable-boot)
            DISABLE_BOOT=1
            ;;
        --disable-styling)
            DISABLE_STYLING=1
            ;;
        --disable-gui)
            DISABLE_GUI=1
            ;;
        --disable-x11)
            DISABLE_X11=1
            ;;
        *)
            echo "[!] Unknown option '$1'"
            show_usage
            exit 1
            ;;
    esac
    shift 1
done

if [ -z "${DO_NOT_CLEAN}" ]; then
    check_names
    clean_docker
    clean_artifacts
    download
    if [ -n "$TERMUX_GENERATOR_PLUGIN" ]; then
        build_plugin
        install_plugin
    fi
    patch_bootstraps
    patch_apps
    if [ -z "${DISABLE_X11}" ]; then
        build_termux_x11
        move_termux_x11_deb
    fi
    if [ -z "${DISABLE_BOOTSTRAP}" ]; then
        build_bootstraps
        move_bootstraps
    fi
fi

if [ -z "${DISABLE_TERMINAL}" ]; then
    build_apps
    move_apks
fi

exit 0