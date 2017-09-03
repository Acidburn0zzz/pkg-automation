function install_symlinks() {
    rm -f /tmp/pkgconfig.conf
    rm -f /tmp/pkgrepo.conf
    rm -f /tmp/pkgscripts

    ln -s ${config} /tmp/pkgconfig.conf
    ln -s ${repo} /tmp/pkgrepo.conf
    ln -s ${TOPDIR} /tmp/pkgscripts
}

function update_ports() {
    (
        cd /usr/ports
        git pull
        exit ${?}
    )

    return ${?}
}

function build_packages() {
    name=$(jq -r '.name' ${repo})

    install_symlinks

    poudriere bulk \
        -j ${name} \
        -p "local" \
        -ca
}

function sign_packages() {
    name=$(jq -r '.name' ${repo})
    datadir=$(jq -r '.datadir' ${config})
    signcmd=$(jq -r '.signcmd' ${config})

    (
        cd ${datadir}/${name}-local/Latest
        sha256 -q pkg.txz | /src/scripts/pkgsign.sh > pkg.txz.sig

        cd ..
        pkg repo . signing_command: /src/scripts/pkgsign.sh
        exit ${?}
    )

    return ${?}
}