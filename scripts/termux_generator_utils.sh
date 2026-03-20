portable_sed_i() {
    if sed v </dev/null 2> /dev/null; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

apply_patches() {
    local srcdir=$(realpath "$1")
    local targetdir=$(realpath "$2")
    local patches=$(find "$srcdir" -type f | sort)

    pushd "$targetdir"

    for patch in $patches; do
        patch -p1 < "$patch"
    done

    popd
}

replace_termux_name() {
    if [[ "$TERMUX_APP__PACKAGE_NAME" == "com.termux" ]]; then
        return
    fi
    local target="$1"
    local replacement_name="$2"
    local replacement_name_underscore="$(echo "$replacement_name" | tr . _)"
    local replacement_name_slash="$(echo "$replacement_name" | tr . /)"

    _sed_file() {
        portable_sed_i -e "s|>Termux<|>$replacement_name<|g" \
                       -e "s|\"Termux\"|\"$replacement_name\"|g" \
                       -e "s|Termux:|$replacement_name:|g" \
                       -e "s|com\.termux|$replacement_name|g" \
                       -e "s|com_termux|$replacement_name_underscore|g" \
                       -e '/http/!s|com/termux|'$replacement_name_slash'|g' "$1"
    }

    if [[ -f "$target" ]]; then
        if file "$target" | grep -q "text"; then
            _sed_file "$target"
        fi
    elif [[ -d "$target" ]]; then
        pushd "$target"
        local file
        find . -type f -exec file {} + | grep "text" | cut -d: -f1 | while read -r file; do
            _sed_file "$file"
        done
        popd
    fi
}

migrate_termux_folder() {
    if [[ "$TERMUX_APP__PACKAGE_NAME" == "com.termux" ]]; then
        return
    fi
    local parentdir="$(dirname "$(dirname "$1")")"
    local replacement_name="$2"
    local destination="${parentdir}/$(echo "$replacement_name" | tr . /)/"

    echo "Migrating: ${parentdir}/com/termux/ -> ${destination}"
    mkdir -p "${destination}"
    mv "${parentdir}/com/termux/"* "${destination}"
    rm -r "${parentdir}/com/termux/"
}

migrate_termux_folder_tree() {
    if [[ "$TERMUX_APP__PACKAGE_NAME" == "com.termux" ]]; then
        return
    fi
    local targetdir="$1"
    local replacement_name="$2"

    pushd "$targetdir"

    local dir
    find "$(pwd)" -type d -name termux | grep -v -e 'shared/termux' -e 'settings/termux' | while read -r dir; do
        migrate_termux_folder "$dir" "$replacement_name"
    done

    popd
}