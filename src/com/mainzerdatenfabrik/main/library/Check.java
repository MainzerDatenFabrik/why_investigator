package com.mainzerdatenfabrik.main.library;

import com.mainzerdatenfabrik.main.utils.VersionComparator;

import java.util.*;

/**
 *
 */
public class Check {

    public enum Type {
        USER, INSTANCE, DATABASE, CUSTOM
    }

    private final String name;

    private final Type type;

    private HashMap<String, String> queries;

    /**
     * The constructor.
     */
    public Check(String name, Type type) {
        this.name = name;
        this.type = type;

        queries = new HashMap<>();
    }

    /**
     * The constructor.
     */
    Check(String name, String minCompatibleVersion, String query, Type type) {
        this.name = name;
        this.type = type;

        queries = new HashMap<>();
        queries.put(minCompatibleVersion, query);
    }

    /**
     *
     * @return the name of the check query (e.g., User Role Info)
     */
    public String getName() {
        return name;
    }

    /**
     *
     * @return the type of the check query (i.e., either "user", "instance" or "database")
     */
    public Type getType() {
        return type;
    }

    /**
     * Adds a new query to a Check object based on a specific version string.
     *
     * @param versionString the version String of the query (i.e., the lowest SQL Server version the query is compatible with)
     * @param query the query itself
     */
    public void addQuery(String versionString, String query) {
        queries.put(versionString, query);
    }

    /**
     * Returns the first query from the queries map, regardless of the version.
     *
     * @return the first query from the queries map; null if map is empty.
     */
    public String getQuery() {
        for(Map.Entry<String, String> e : queries.entrySet())
            return e.getValue();
        return null;
    }

    /**
     * Returns the query corresponding to a specific version string.
     *
     * @param versionString the version string to identify the query with
     *
     * @return the query identified by the version string, "null" if not query could be identified
     */
    public String getQuery(String versionString) {
        if(queries.containsKey(versionString)) {
            return queries.get(versionString);
        } else {
            // find the version string that matches the most
            String closest = findClosest(queries.keySet(), versionString);
            if(closest == null) {
                return null;
            }
            return queries.get(closest);
        }
    }

    /**
     * Finds the best matching version string (i.e., the version string that is below, but the closest to the original)
     * from a set of version strings based on a specific version string
     *
     * @param keys the set of version strings to choose from
     * @param versionString the original version string
     *
     * @return null, if no other version string was found; else, the best matching version string
     */
    private String findClosest(Set<String> keys, String versionString) {
        ArrayList<String> versions = new ArrayList<>(keys);
        Collections.sort(versions);

        String bestSoFar = null;

        for(String version : versions) {
            if(VersionComparator.comp(versionString, version) >= 0) {
                if(bestSoFar == null || VersionComparator.comp(version, bestSoFar) >= 0) {
                    bestSoFar = version;
                }
            }
        }

        return bestSoFar;
    }
}
