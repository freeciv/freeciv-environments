#!/bin/bash

if test "$1" = "-v" || test "$1" = "--version" ; then
  echo "Freeciv build script for Linux Manjaro version 1.11"
  exit
fi

if test "$1" = "" || test "$2" = "" ||
   test "$1" = "-h" || test "$1" = "--help" ; then
  echo "Usage: $0 <release> <gui> [main dir=freeciv-genbuild] [download URL]"
  echo "Supported releases are those of 2.6, 3.0, 3.1, and 3.2 major versions"  
  echo "Supported guis are 'gtk2', 'gtk3.22', 'gtk3', 'gtk4', 'qt'"
  echo "URL must point either to tar.bz2 or tar.xz package"
  exit
fi

REL="$1"
GUI="$2"

if test "$3" = "" ; then
  MAINDIR="freeciv-genbuild"
else
  MAINDIR="$3"
fi

FREECIV_MAJMIN=$(echo "$REL" | sed 's/\./ /g' | (read MAJOR MINOR REST ; echo -n "$MAJOR.$MINOR"))

if test "$FREECIV_MAJMIN" = "3.1" ; then
  FREECIV_PATCH=$(echo "$REL" | sed 's/\./ /g' | (read MAJOR MINOR PATCH REST ; echo -n "$PATCH"))
  if test "$FREECIV_PATCH" = "" || test "$FREECIV_PATCH" -ge 90 ; then
    FREECIV_MAJMIN="3.2"
  fi
fi

if test "$FREECIV_MAJMIN" != "2.6" &&
   test "$FREECIV_MAJMIN" != "3.0" &&
   test "$FREECIV_MAJMIN" != "3.1" &&
   test "$FREECIV_MAJMIN" != "3.2" ; then
  echo "Release '$REL' from unsupported branch. See '$0 --help' for supported options" >&2
  exit 1
fi

if test "$GUI" != "gtk3.22" &&
   test "$GUI" != "gtk3" &&
   test "$GUI" != "gtk2" &&
   test "$GUI" != "gtk4" &&
   test "$GUI" != "qt" ; then
  echo "Unsupported gui '$GUI' given. See '$0 --help' for supported options" >&2
  exit 1
fi

if test "$GUI" = "gtk2" ; then
  if test "$FREECIV_MAJMIN" != "2.6" &&
     test "$FREECIV_MAJMIN" != "3.0" ; then
    echo "gtk2 is not supported gui for freeciv-3.1 or later" >&2
    exit 1
  fi
fi

if test "$GUI" = "gtk3" ; then
  if test "$FREECIV_MAJMIN" != "2.6" &&
     test "$FREECIV_MAJMIN" != "3.0" &&
     test "$FREECIV_MAJMIN" != "3.1" ; then
    echo "gtk3 is not supported gui for freeciv-3.2 or later" >&2
    exit 1
  fi
fi

if test "$GUI" = "gtk4" ; then
  if test "$FREECIV_MAJMIN" = "2.6" ||
     test "$FREECIV_MAJMIN" = "3.0" ; then
    echo "gtk4 is not supported gui for freeciv-3.0 or earlier" >&2
    exit 1
  fi
fi

echo "Install requirements (y/n)?"
echo "You need them, so answer 'n' only if you have them already"
echo "in place."
while test "$req_install" != "n" && test "$req_install" != "y"
do
  echo -n "> "
  read -n 1 req_install
  echo
  if test "$req_install" != "n" && test "$req_install" != "y" ; then
    echo "Please answer 'y' or 'n'"
  fi
done

if test "$req_install" != "n" ; then
echo "Installing requirements"
sudo pacman -Su --needed \
  gcc make sdl2_mixer pkg-config meson
fi

if test -d "$MAINDIR" ; then
  echo "There's already directory called '$MAINDIR'. Should I use it?"
  echo "y)es or no?"
  echo -n "> "
  read -n 1 ANSWER
  echo
  if test "x$ANSWER" != "xy" ; then
    echo "Didn't get definite yes for using existing directory. Aborting"
    exit 1
  fi
fi

if ! mkdir -p "$MAINDIR" ; then
  echo "Failed to create directory '$MAINDIR'" >&2
  exit 1
fi

if ! cd "$MAINDIR" ; then
  echo "Can't go to '$MAINDIR' directory" >&2
  exit 1
fi

export FREECIV_MAINDIR=$(pwd)

if ! test -f freeciv-$REL.tar.bz2 && ! test -f freeciv-$REL.tar.xz ; then
  echo "Downloading freeciv-$REL"
  if test "$4" = "" ; then
    if test "$FREECIV_MAJMIN" = "2.6" ; then
      URL="https://sourceforge.net/projects/freeciv/files/Freeciv $FREECIV_MAJMIN/$REL/freeciv-$REL.tar.bz2"
    else
      URL="https://sourceforge.net/projects/freeciv/files/Freeciv $FREECIV_MAJMIN/$REL/freeciv-$REL.tar.xz"
    fi
  else
    URL="$4"
  fi
  if ! wget "$URL" ; then
    echo "Can't download freeciv release freeciv-$REL from $URL." >&2
    exit 1
  fi
else
  echo "freeciv-$REL already downloaded"
fi

if ! test -d "freeciv-$REL" ; then
  echo "Unpacking freeciv-$REL"
  if test -f freeciv-$REL.tar.xz ; then
    if ! mkdir -p freeciv-$REL ||
       ! tar xJf freeciv-$REL.tar.xz -C freeciv-$REL --strip-components 1 ; then
      echo "Failed to unpack freeciv-$REL.tar.xz" >&2
      exit 1
    fi
  elif ! tar xjf freeciv-$REL.tar.bz2 ; then
    echo "Failed to unpack freeciv-$REL.tar.bz2" >&2
    exit 1
  fi
else
  echo "freeciv-$REL source directory already exist"
fi

if ! cd "freeciv-$REL" ; then
  echo "Failed to go to source directory freeciv-$REL" >&2
  exit 1
fi

if ! cd "$FREECIV_MAINDIR" ; then
  echo "Failed to return to main directory '$FREECIV_MAINDIR'" >&2
  exit 1
fi

if ! mkdir -p "builds-$REL/$GUI" ; then
  echo "Failed to create build directory 'builds-$REL/$GUI'" >&2
  exit 1
fi

if test -f "install-$REL/$GUI" ; then
  echo "Removing old $REL $GUI installation directory"
  if ! rm -Rf "install-$REL/$GUI" ; then
    echo "Failed to remove old installation directory" >&2
    exit 1
  fi
fi

if ! cd "builds-$REL/$GUI" ; then
  echo "Failed to go to directory builds-$REL/$GUI" >&2
  exit 1
fi

if test "$GUI" = "gtk4" ; then
  FCMP="gtk4"
elif test "$GUI" = "gtk2" ; then
  FCMP="gtk2"
elif test "$GUI" = "qt" ; then
  FCMP="qt"
else
  FCMP="gtk3"
fi

if test "$FREECIV_MAJMIN" = "2.6" ||
   test "$FREECIV_MAJMIN" = "3.0" ||
   test "$FREECIV_MAJMIN" = "3.1" ; then
  echo "configure"
  if ! ../../freeciv-$REL/configure --prefix=$FREECIV_MAINDIR/install-$REL/$GUI --enable-client=$GUI --enable-fcmp=$FCMP $EXTRA_CONFIG ; then
    echo "Configure failed" >&2
    exit 1
  fi

  echo "make"
  if ! make ; then
    echo "Make failed" >&2
    exit 1
  fi

  echo "make install"
  if ! make install ; then
    echo "'Make install' failed" >&2
    exit 1
  fi
else
  echo "meson"
  if ! meson setup ../../freeciv-$REL -Ddefault_library=static -Dprefix=$FREECIV_MAINDIR/install-$REL/$GUI -Dclients=$GUI -Dfcmp=$FCMP ; then
    echo "Meson failed" >&2
    exit 1
  fi

  echo "ninja"
  if ! ninja ; then
    echo "Ninja failed" >&2
    exit 1
  fi

  echo "ninja install"
  if ! ninja install ; then
    echo "Ninja install failed" >&2
    exit 1
  fi
fi

echo
echo "freeciv-$REL $GUI installation is now at $FREECIV_MAINDIR/install-$REL/$GUI"
echo "The programs available there are:"
ls -1 "$FREECIV_MAINDIR/install-$REL/$GUI/bin" | sed "s|^|$FREECIV_MAINDIR/install-$REL/$GUI/bin/|"
