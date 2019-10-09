package com.mainzerdatenfabrik.main.utils;

import java.util.Comparator;

public class VersionComparator implements Comparator<String> {

    // The comparator used to compare two version strings with one and another
    // Used to determine if a specific check from the CheckLibrary can be executed on the server currently connected to
    private static final VersionComparator VERSION_COMPARATOR = new VersionComparator();

    /**
     * Compares two version strings with one and another, where:
     *      - 0 means they are equal
     *      - pos. value means "o1" is greater than "o2"
     *      - neg. value means "o1" is smaller than "o2"
     *
     * @param o1 - the version string (i.e., the version string of the server)
     * @param o2 - the version string to compare "o1" to (i.e., the version string of the query)
     *
     * @return - value between 1 and -1
     */
    @Override
    public int compare(String o1, String o2) {

        String[] splitO1 = o1.split("\\.");
        String[] splitO2 = o2.split("\\.");

        for(int i = 0; i < splitO1.length; i++) {
            if(Integer.parseInt(splitO1[i]) > Integer.parseInt(splitO2[i])) {
                return 1;
            }
            if(Integer.parseInt(splitO1[i]) < Integer.parseInt(splitO2[i])) {
                return -1;
            }
        }
        return 0;
    }

    /**
     *
     * @return
     */
    public static int comp(String s1, String s2) {
        return VERSION_COMPARATOR.compare(s1, s2);
    }
}
