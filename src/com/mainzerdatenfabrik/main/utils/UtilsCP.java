package com.mainzerdatenfabrik.main.utils;

public class UtilsCP {

    // The max length of a module label including name and online/offline indicator
    public static final int MAX_MODULE_LABEL_LENGTH = 42;

    // The max length of a module status label
    public static final int MAX_MODULE_STATUS_LABEL_LENGTH = 40;

    // The amount of time to show the welcome screen for.
    public static final int WELCOME_SCREEN_TIME = 500;

    // Some colors to paint the terminal text with.
    // ANSI_RESET has to be used to end the coloring of a string.
    public static final String ANSI_RESET = "\u001B[0m";
    public static final String ANSI_BLACK = "\u001B[30m";
    public static final String ANSI_RED = "\u001B[31m";
    public static final String ANSI_GREEN = "\u001B[32m";
    public static final String ANSI_YELLOW = "\u001B[33m";
    public static final String ANSI_BLUE = "\u001B[34m";
    public static final String ANSI_PURPLE = "\u001B[35m";
    public static final String ANSI_CYAN = "\u001B[36m";
    public static final String ANSI_WHITE = "\u001B[37m";
    
    public static final String ASCII_OWL =
            "        _________" +
                    "       /_  ___   \\" +
                    "      /@ \\/@  \\   \\" +
                    "      \\__/\\___/   /" +
                    "       \\_\\/______/" +
                    "       /     /\\\\\\\\\\" +
                    "      |     |\\\\\\\\\\\\" +
                    "       \\      \\\\\\\\\\\\" +
                    "        \\______/\\\\\\\\" +
                    "  _______ ||_||_______" +
                    " (______(((_(((______(@)";

    // Welcome screen
    public static String w01 = "┌──────────────────────────────────────────────────────────────────────────────┐\n";
    public static String w02 = "│                                                                              │\n";
    public static String w03 = "│                                                                              │\n";
    public static String w04 = "│                                                                              │\n";
    public static String w05 = "│                                                                              │\n";
    public static String w06 = "│                                                                              │\n";
    public static String w07 = "│                                                                              │\n";
    public static String w08 = "│\u001B[36m           _           _                     _   _             _              \u001B[0m│\n";
    public static String w09 = "│\u001B[36m          | |         (_)                   | | (_)           | |             \u001B[0m│\n";
    public static String w10 = "│\u001B[36m __      _| |__  _   _ _ _ ____   _____  ___| |_ _  __ _  __ _| |_ ___  _ __  \u001B[0m│\n";
    public static String w11 = "│\u001B[36m \\ \\ /\\ / / '_ \\| | | | | '_ \\ \\ / / _ \\/ __| __| |/ _` |/ _` | __/ _ \\| '__| \u001B[0m│\n";
    public static String w12 = "│\u001B[36m  \\ V  V /| | | | |_| | | | | \\ V /  __/\\__ \\ |_| | (_| | (_| | || (_) | |    \u001B[0m│\n";
    public static String w13 = "│\u001B[36m   \\_/\\_/ |_| |_|\\__, |_|_| |_|\\_/ \\___||___/\\__|_|\\__, |\\__,_|\\__\\___/|_|    \u001B[0m│\n";
    public static String w14 = "│\u001B[36m                  __/ |                             __/ |                     \u001B[0m│\n";
    public static String w15 = "│\u001B[36m                 |___/                             |___/                      \u001B[0m│\n";
    public static String w16 = "│                                                                              │\n";
    public static String w17 = "│                                                                              │\n";
    public static String w18 = "│                                                                              │\n";
    public static String w19 = "│                                                                              │\n";
    public static String w20 = "│                                                                              │\n";
    public static String w21 = "│                                                                              │\n";
    public static String w22 = "│                                                                              │\n";
    public static String w23 = "│                                                                              │\n";
    public static String w24 = "└──────────────────────────────────────────────────────────────────────────────┘\n";

    // Confirm screen
    public static String c01 = "┌──────────────────────────────────────────────────────────────────────────────┐\n";
    public static String c02 = "│                                                                              │\n";

    public static String c03 = "│                                                                              │\n";
    public static String c04 = "│                          [Y] Yes          [N] No                             │\n";
    public static String c05 = "│                                                                              │\n";
    public static String c06 = "└──────────────────────────────────────────────────────────────────────────────┘\n";

    // Synchronizer mode screen
    public static String sm01 = "┌──────────────────────────────────────────────────────────────────────────────┐\n";
    public static String sm02 = "│                                                                              │\n";

    public static String sm03 = "│              [d] Transfer via IP-Connection (direct)                         │\n";
    public static String sm04 = "│              [i] Transfer via JSON-Files  (indirect)                         │\n";
    public static String sm05 = "│                                                                              │\n";
    public static String sm06 = "└──────────────────────────────────────────────────────────────────────────────┘\n";

    // Info screen
    public static String i01 = "┌──────────────────────────────────────────────────────────────────────────────┐\n";
    public static String i02 = "│                                                                              │\n";

    public static String i03 = "│                                                                              │\n";
    public static String i04 = "│                            [Hit Enter to return]                             │\n";
    public static String i05 = "│                                                                              │\n";
    public static String i06 = "└──────────────────────────────────────────────────────────────────────────────┘\n";

    // Input info screen
    public static String in01 = "┌──────────────────────────────────────────────────────────────────────────────┐\n";
    public static String in02 = "│                                                                              │\n";

    public static String in03 = "│                                                                              │\n";
    public static String in04 = "│                                                                              │\n";
    public static String in05 = "│                                                                              │\n";
    public static String in06 = "└──────────────────────────────────────────────────────────────────────────────┘\n";

    // Synchronizer selection screen
    public static String sc01 = "┌──────────────────────────────────────────────────────────────────────────────┐\n";
    public static String sc02 = "│                                                                              │\n";

    public static String sc03 = "│                                                                              │\n";
    public static String sc04 = "│ [A]   Select all                                                             │\n";
    public static String sc05 = "│ [U] Unselect all                                           [C] Continue      │\n";
    public static String sc06 = "└──────────────────────────────────────────────────────────────────────────────┘\n";

    // Main Screen
    public static String m01 = "┌──────────────────────────────────────────────────────────────────────────────┐\n";
    public static String m02 = "│                                                                              │\n";
    public static String m03 = "│                                                                              │\n";
    //public static String m03_1 = "│                                    │\n";
    //public static String m03_2 = "                               │\n";
    public static String m04 = "│                                                                              │\n";
    //public static String m04_1 = "│     - ";
    //public static String m04_2 = "                               │\n";
    public static String m05 = "│                                                          \u001B[36m_________\u001B[0m           │\n";
    public static String m05_1 = "│     ";
    public static String m05_2 = "           \u001B[36m_________\u001B[0m           │\n";
    public static String m06 = "│                                                         \u001B[36m/_  ___   \\\u001B[0m          │\n";
    public static String m07 = "";
    public static String m07_1 = "│     ";
    public static String m07_2 = "         \u001B[36m/@ \\/@  \\   \\\u001B[0m         │\n";
    public static String m08 = "│                                                        \u001B[36m\\__/\\___/   /\u001B[0m         │\n";
    //public static String m08_1 = "│     - ";
    //public static String m08_2 = "         \u001B[36m\\__/\\___/   /\u001B[0m         │\n";
    public static String m09 = "│                                                         \u001B[36m\\_\\/______/\u001B[0m          │\n";
    public static String m09_1 = "│     ";
    public static String m09_2 = "          \u001B[36m\\_\\/______/\u001B[0m          │\n";
    public static String m10 = "│                                                         \u001B[36m/     /\\\\\\\\\\\\\u001B[0m        │\n";
    //public static String m11 = "│                                                        \u001B[36m|     |\\\\\\\\\\\\\u001B[0m         │\n";
    public static String m11 = "│                                                        \u001B[36m|     |\\\\\\\\\\\\\\\\\\\\\u001B[0m     │\n";
    //public static String m11_1 = "│     ";
    //public static String m11_2 = "         \u001B[36m|     |\\\\\\\\\\\\\\\\\\\\\u001B[0m     │\n";
    //public static String m12 = "│                                                         \u001B[36m\\      \\\\\\\\\\\\\u001B[0m        │\n";
    public static String m12 = "│                                                         \u001B[36m\\\\      \\\\\\\\\\\\\\\\\u001B[0m     │\n";
    //public static String m12_1 = "│     - ";
    //public static String m12_2 = "          \u001B[36m\\\\      \\\\\\\\\\\\\\\\\u001B[0m     │\n";
    public static String m13 = "│                                                          \u001B[36m\\\\______/\\\\\\\\\\\\\u001B[0m     │\n";
    public static String m14 = "│                                                            \u001B[36m|| ||\u001B[0m             │\n";
    public static String m15 = "├─────Please─select─a─command──────────────────────────────\u001B[36m(((\u001B[0m─\u001B[36m(((\u001B[0m─────────────┤\n";
    public static String m16 = "│                                                                              │\n";
    public static String m17 = "│     - [1] Start SQLWorker               - [5] Stop SQLWorker                 │\n";
    public static String m18 = "│     - [2] Start FileWatcher             - [6] Stop FileWatcher               │\n";
    public static String m19 = "│     - [3] Start Processor               - [7] Stop Processor                 │\n";
    public static String m20 = "│     - [4] Open RemoteController                                              │\n";
    public static String m21 = "│                                                                              │\n";
    public static String m22 = "└──────────────────────────────────────────────────────────────────────────────┘\n";
    public static String m23 = "[E] Exit                                                     [H] Help [A] About \n";

    // Remote control screen
    public static String r01 = "┌──────────────────────────────────────────────────────────────────────────────┐\n";
    public static String r02 = "│                                                                              │\n";
    public static String r03  = "";
    public static String r03_1 = "│     ";
    public static String r03_2 = "                               │\n";
    public static String r04 = "│                                                                              │\n";
    public static String r05 = "";
    public static String r05_1 = "│     ";
    public static String r05_2 = "           \u001B[36m_________\u001B[0m           │\n";
    public static String r06 = "│                                                         \u001B[36m/_  ___   \\\u001B[0m          │\n";
    public static String r07 = "";
    public static String r07_1 = "│     ";
    public static String r07_2 = "         \u001B[36m/@ \\/@  \\   \\\u001B[0m         │\n";
    public static String r08 = "│                                                        \u001B[36m\\__/\\___/   /\u001B[0m         │\n";
    public static String r09 = "│                                                         \u001B[36m\\_\\/______/\u001B[0m          │\n";
    public static String r10 = "│                                                                    \u001B[36m/     /\\\\\\\\\\\\\u001B[0m        │\n";
    public static String r10_1 = "│     ";
    public static String r10_2 = "          \u001B[36m/     /\\\\\\\\\\\\\u001B[0m        │\n";
    public static String r11 = "";
    public static String r11_1 = "│     ";
    public static String r11_2 = "         \u001B[36m|     |\\\\\\\\\\\\\\\\\\\\\u001B[0m     │\n";
    public static String r12 = "";
    public static String r12_1 = "│     ";
    public static String r12_2 = "          \u001B[36m\\\\      \\\\\\\\\\\\\\\\\u001B[0m     │\n";
    public static String r13 = "";
    public static String r13_1 = "│     ";
    public static String r13_2 = "           \u001B[36m\\\\______/\\\\\\\\\\\\\u001B[0m     │\n";
    public static String r14 = "│                                                            \u001B[36m|| ||\u001B[0m             │\n";
    public static String r15 = "├─────Please─select─a─command─to─execute─remotely──────────\u001B[36m(((\u001B[0m─\u001B[36m(((\u001B[0m─────────────┤\n";
    public static String r16 = "│                                                                              │\n";
    public static String r17 = "│     - [1] Start SQLWorker               - [5] Stop SQLWorker                 │\n";
    public static String r18 = "│     - [2] Start FileWatcher             - [6] Stop FileWatcher               │\n";
    public static String r19 = "│     - [3] Start Processor               - [7] Stop Processor                 │\n";
    public static String r20 = "│     - [4] Terminate Program             - [8]                                │\n";
    public static String r21 = "│                                                                              │\n";
    public static String r22 = "└──────────────────────────────────────────────────────────────────────────────┘\n";
    public static String r23 = "[R] Return                                                             [H] Help \n";
    
    /**
     * Adds ANSI-Color and ANSI-Rest to a string. This is used to give strings color on the console.
     *
     * @param color the desired color of the string
     * @param str the string to be colored
     *
     * @return the colored string
     */
    public static String paintString(String color, String str) {
        return color + str + UtilsCP.ANSI_RESET;
    }
}
