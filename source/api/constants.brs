' Set global constants
sub setConstants()

    globals = m.screen.getGlobalNode()

    ' Set Global Constants
    globals.addFields({
        constants: {

            poster_bg_pallet: ["#00455c", "#44bae1", "#00a4db", "#1c4c5c", "#007ea8"],

            colors: {
                button: "#006fab"
            },

            icons: {
                ascending_black: "pkg:/images/icons/up_black.png",
                ascending_white: "pkg:/images/icons/up_white.png",
                descending_black: "pkg:/images/icons/down_black.png",
                descending_white: "pkg:/images/icons/down_white.png"
                check_black: "pkg:/images/icons/check_black.png",
                check_white: "pkg:/images/icons/check_white.png"
            }


        }
    })



end sub