# THIS IS DEPRECATED AND MOVED TO DOWNLOADS.SH

####################################################################
# Resets sources.list to factory state in case of red team poisoning
# Written by Guac.0
####################################################################

# Issues:
# Very WIP. See TODO notes throughout the code
# Common issues: 
# Are we resetting to right default repos?
# Are we resetting all the various permutations of sources.list (such as .d)?
# different archectures :()
# TESTING

# Import the OS variables
# Needs os_detection.sh to run first
PATH_TO_OS_RESULTS_FILE="./os.txt"
if [ -f $PATH_TO_OS_RESULTS_FILE ] ; then
    source $PATH_TO_OS_RESULTS_FILE
else
    echo "Operating System information file (as produced by os_detection.sh) not found! Exiting..."
    exit
fi

# check for root for installs and exit if not found
if  [ "$EUID" -ne 0 ];
then
    echo "User is not root. Skill issue."
    exit
fi

echo "Attempting to reset sources.list (or equivalent) to default value..."
echo "OS detected: $OS_NAME"

# Change depending on OS
if $DEBIAN ; then
    # TODO restore sources.list.d?
    # TODO test

    mv /etc/apt/sources.list /etc/apt/sources.list.backup
    mv /etc/apt/sources.list.d /etc/apt/sources.list.d.backup
    mkdir /etc/apt/sources.list.d

    if $UBUNTU ; then 
        #Ubuntu
        # Get Ubuntu version codename
        ubuntu_version=$(lsb_release -sc)

        # Define sources.list entries based on Ubuntu version
        # TODO this includes the tabs, no functional value lost but its annoying
        sources_list_entries="
        deb http://us.archive.ubuntu.com/ubuntu/ $ubuntu_version main restricted
        # deb-src http://us.archive.ubuntu.com/ubuntu/ $ubuntu_version main restricted
        deb http://us.archive.ubuntu.com/ubuntu/ ${ubuntu_version}-security main restricted
        # deb-src http://us.archive.ubuntu.com/ubuntu/ ${ubuntu_version}-security main restricted
        "
    else
        #Debian
        # Get Debian version codename
        debian_version=$(lsb_release -sc)

        # Define sources.list entries based on Debian version
        sources_list_entries="
        deb http://ftp.us.debian.org/debian/ $debian_version main
        # deb-src http://ftp.us.debian.org/debian/ $debian_version main
        deb http://ftp.us.debian.org/debian/ ${debian_version}-security main
        # deb-src http://ftp.us.debian.org/debian/ ${debian_version}-security main
        "
    fi

    # Write new entries to sources.list
    # Why does chatgpt like to use tee here?
    echo "$sources_list_entries" | tee /etc/apt/sources.list > /dev/null

    # Add appropriate permissions to sources.list (should be done automatically by tee, but still)
    # TODO do all the OSes need this?
    chmod 644 /etc/apt/sources.list

    # Update package lists
    apt update

    echo "/etc/apt/sources.list and /etc/apt/sources.list.d have been reset!"
    echo "You can find their original files at the same file path, just renamed with the suffix '.backup'"

elif $REDHAT || $RHEL; then
    # TODO test
    # TODO are these the minimal/necessary repos?
    # TODO does this os have a sources.list.d equivalent?

    # Get RHEL or CentOS version
    #rhel_version=$(rpm -E %{rhel})

    # Define repository entries based on RHEL or CentOS version
    : '
    repo_entries="
    [base]
    name=Red Hat Enterprise Linux \$releasever - Base
    baseurl=http://mirror.centos.org/centos/\$releasever/os/\$basearch/
    gpgcheck=1
    enabled=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

    [updates]
    name=Red Hat Enterprise Linux \$releasever - Updates
    baseurl=http://mirror.centos.org/centos/\$releasever/updates/\$basearch/
    gpgcheck=1
    enabled=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

    [extras]
    name=Red Hat Enterprise Linux \$releasever - Extras
    baseurl=http://mirror.centos.org/centos/\$releasever/extras/\$basearch/
    gpgcheck=1
    enabled=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
    "
    '

    # Backup existing yum configuration
    # mv /etc/yum.repos.d/redhat.repo /etc/yum.repos.d/redhat.repo.backup

    # Apparently after deleting redhat.repo, you can run this command to rebuild the list
    # Dunno how reliable it is...
    #subscription-manager refresh

    # Write new entries to yum configuration
    # echo "$repo_entries" | tee /etc/yum.repos.d/redhat.repo > /dev/null

    # Clean metadata and refresh repositories
    # yum clean all
    # yum makecache

    # New method from here: https://access.redhat.com/discussions/5471181#comment-1929481

    # Backup existing yum configuration
    mv /etc/yum.repos.d/ /etc/yum.repos.d.backup

    yum clean all

    rm -r /var/cache/yum/*
    rm -r /etc/yum.repos.d/*

    subscription-manager remove --all
    subscription-manager unregister
    subscription-manager clean

    subscription-manager register
    subscription-manager refresh

    subscription-manager list --available
    # I dunno what a pool is so lets auto register
    #subscription-manager attach --pool=<Pool-ID>
    subscription-manager attach --auto

    yum update

    echo "/etc/yum.repos.d has been reset!"
    echo "You can find the original file at the same file path, just renamed with the suffix '.backup'"
    
elif $AMZ ; then 
    # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/add-repositories.html
    # TODO this is only for amazon linux 2!
    # TODO test
    # TODO are these the minimal/necessary repos?
    # TODO does this os have a sources.list.d equivalent?

    # Define repository entries for Amazon Linux
    repo_entries="
    [amzn-main]
    name=Amazon Linux 2 - amzn-main
    mirrorlist=http://amazonlinux.us-east-1.amazonaws.com/2/core/latest/x86_64/mirror.list
    enabled=1
    gpgcheck=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-amazon-linux-2

    [amzn-updates]
    name=Amazon Linux 2 - amzn-updates
    mirrorlist=http://amazonlinux.us-east-1.amazonaws.com/2/updates/latest/x86_64/mirror.list
    enabled=1
    gpgcheck=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-amazon-linux-2
    "

    # Backup existing yum configuration
    mv /etc/yum.repos.d/amzn2-core.repo /etc/yum.repos.d/amzn2-core.repo.backup

    # Write new entries to yum configuration
    echo "$repo_entries" | tee /etc/yum.repos.d/amzn2-core.repo > /dev/null

    # Clean metadata and refresh repositories
    yum clean all
    yum makecache

    echo "/etc/yum.repos.d/amzn2-core.repo has been reset!"
    echo "You can find the original file at the same file path, just renamed with the suffix '.backup'"

elif $ALPINE ; then 
    # TODO test
    # TODO are these the minimal/necessary repos?
    # TODO does this os have a sources.list.d equivalent?

    # Define repository entries for Alpine Linux
    repo_entries="
    http://dl-cdn.alpinelinux.org/alpine/v3.14/main
    http://dl-cdn.alpinelinux.org/alpine/v3.14/community
    "

    # Backup existing apk configuration
    mv /etc/apk/repositories /etc/apk/repositories.backup

    # Write new entries to apk configuration
    echo "$repo_entries" | tee /etc/apk/repositories > /dev/null

    # Update the package index
    apk update

elif $SLACK ; then 
    # TODO test
    # TODO are these the minimal/necessary repos?
    # TODO does this os have a sources.list.d equivalent?

    # Define repository entries for Slackware
    repo_entries="
    http://mirrors.slackware.com/slackware/slackware64-14.2/
    "

    # Backup existing slackpkg mirrors configuration
    mv /etc/slackpkg/mirrors /etc/slackpkg/mirrors.backup

    # Write new entries to slackpkg mirrors configuration
    echo "$repo_entries" | tee /etc/slackpkg/mirrors > /dev/null

    # Update the package list
    slackpkg update

    echo "/etc/slackpkg/mirrors has been reset!"
    echo "You can find the original file at the same file path, just renamed with the suffix '.backup'"

elif $FEDORA ; then 
    # TODO test
    # TODO are these the minimal/necessary repos?
    # TODO does this os have a sources.list.d equivalent?

    # Get Fedora version
    fedora_version=$(rpm -E %fedora)

    # Define repository entries based on Fedora version
    repo_entries="
    [main]
    name=Fedora \$releasever - \$basearch
    metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-\$releasever&arch=\$basearch
    enabled=1
    gpgcheck=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-\$releasever-\$basearch

    [updates]
    name=Fedora \$releasever - Updates
    metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f\$releasever&arch=\$basearch
    enabled=1
    gpgcheck=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-\$releasever-\$basearch
    "

    # Backup existing dnf configuration
    mv /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora.repo.backup

    # Write new entries to dnf configuration
    echo "$repo_entries" | tee /etc/yum.repos.d/fedora.repo > /dev/null

    # Clean metadata and refresh repositories
    dnf clean all
    dnf makecache

    echo "/etc/yum.repos.d/fedora.repo has been reset!"
    echo "You can find the original file at the same file path, just renamed with the suffix '.backup'"

fi

echo "Sources.list reset finished!"