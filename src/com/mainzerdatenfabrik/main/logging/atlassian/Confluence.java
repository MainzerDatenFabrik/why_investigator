package com.mainzerdatenfabrik.main.logging.atlassian;

import org.apache.commons.io.IOUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPut;
import org.apache.http.entity.ContentType;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.http.util.EntityUtils;
import org.json.JSONObject;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;

public class Confluence {

    private static final String MESSAGE_ENCODING = "UTF-8";

    private static final String[] EXPANSIONS = new String[]{"body.storage", "version", "ancestors"};

    // Default values ---------

    private static final String USERNAME = "";
    private static final String PASSWORD = "";

    //private static final String URL = "http://localhost:1990/confluence";
    private static final String URL = "https://conflu.atlassian.net";

    private static final int PAGE_ID = 193232897;

    // ------------------------

    /**
     * Prints a specific message to a confluence page specified by the default values of this class.
     *
     * @param message the specific message to send
     */
    public static void printMessageToPage(String message) {
        printMessageToPage(USERNAME, PASSWORD, URL, PAGE_ID, message);
    }

    /**
     * Prints a specific message to a confluence page specified by the base url and a unique pageId.
     *
     * @param username the username to use for authentication
     * @param password the password corresponding to the username used for authentication
     * @param url the base url of the confluence server
     * @param pageId the id of the page to write to
     * @param message the message to write to the page
     */
    public static String printMessageToPage(String username, String password, String url, int pageId, String message) {
        String pageObject = getPageObject(username, password, url, pageId);
        if(pageObject == null) {
            // logging
            // early exit
            return "Oops! Something went wrong.";
        }

        JSONObject page = new JSONObject(pageObject);

        // Update the page
        // The updated value must be Confluence Storage Format (https://confluence.atlassian.com/display/DOC/Confluence+Storage+Format),
        // not HTML.
        page.getJSONObject("body").getJSONObject("storage").put("value", message);

        // Update the page version
        int version = page.getJSONObject("version").getInt("number");
        page.getJSONObject("version").put("number", version + 1);

        // Send update request
        try(CloseableHttpClient client = HttpClientBuilder.create().build()) {
            HttpEntity pageEntity;

            HttpPut pageRequest = new HttpPut(getContentRestURL(username, password, url, pageId, new String[]{}));

            StringEntity entity = new StringEntity(page.toString(), ContentType.APPLICATION_JSON);
            pageRequest.setEntity(entity);

            HttpResponse pageResponse =   client.execute(pageRequest);
            pageEntity = pageResponse.getEntity();

            //logging
            //Put page request returned: pageResponse.getStatusLine().toString()
            EntityUtils.consume(pageEntity);

            return pageResponse.getStatusLine().toString();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return "Oops! Something went wrong.";
    }

    /**
     *
     * Retrieves and returns a pageObject in string representation based on a specific url and a pageId uniquely
     * identifying the page to retrieve.
     *
     * @param username the username to use for authentication
     * @param password the password corresponding to the username used for authentication
     * @param url the base url of the confluence server
     * @param pageId the id of the page to retrieve
     *
     * @return the specified pageObject in string format if successful, else null
     */
    private static String getPageObject(String username, String password, String url, int pageId) {
        try(CloseableHttpClient client = HttpClientBuilder.create().build()) {

            String contentRestURL = getContentRestURL(username, password, url, pageId, EXPANSIONS);
            if(contentRestURL == null) {
                //logging
                return null;
            }

            HttpGet pageRequest = new HttpGet(contentRestURL);
            //pageRequest.addHeader("Content-Type", "application/json");
            String auth = username + ":" + password;
            pageRequest.addHeader("Authorization:", "Basic " + java.util.Base64.getUrlEncoder().encodeToString(auth.getBytes()));
            HttpResponse pageResponse = client.execute(pageRequest);
            HttpEntity pageEntity = pageResponse.getEntity();

            String pageObject = IOUtils.toString(pageEntity.getContent(), MESSAGE_ENCODING);

            EntityUtils.consume(pageEntity);

            //Logging here
            return pageObject;

        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * Returns the content rest url for a specific url in string format, based on a specific contentId and expressions
     * to be used in the url.
     *
     * @param username the username to use for authentication
     * @param password the password corresponding to the username used for authentication
     * @param url the base url of the confluence server
     * @param contentId the id of the content (i.e., the id of the page to write to)
     * @param expansions an array of values to identify what attributes to retrieve from the page
     *
     * @return the content rest url if successful, else null
     */
    private static String getContentRestURL(String username, String password, String url, final long contentId, final String[] expansions) {
        try {
            String expand = URLEncoder.encode(StringUtils.join(expansions, ","), MESSAGE_ENCODING);
            return String.format("%s/rest/api/content/%s?expand=%s",
                    url,
                    contentId,
                    expand);

        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     *
     *
     * OLD:
     * THE AUTHENTICATION VIA USER/PASSWORD IN THE URL IS NO LONGER SUPPORTED BY ATLASSIAN.
     *
     *
     * Returns the content rest url for a specific url in string format, based on a specific contentId and expressions
     * to be used in the url.
     *
     * @param username the username to use for authentication
     * @param password the password corresponding to the username used for authentication
     * @param url the base url of the confluence server
     * @param contentId the id of the content (i.e., the id of the page to write to)
     * @param expansions an array of values to identify what attributes to retrieve from the page
     *
     * @return the content rest url if successful, else null
     */
    private static String getContentRestURL_old(String username, String password, String url, final long contentId, final String[] expansions) {
        try {
            String expand = URLEncoder.encode(StringUtils.join(expansions, ","), MESSAGE_ENCODING);
            return String.format("%s/rest/api/content/%s?expand=%s&os_authType=basic&os_username=%s&os_password=%s",
                    url,
                    contentId,
                    expand,
                    URLEncoder.encode(username, MESSAGE_ENCODING),
                    URLEncoder.encode(password, MESSAGE_ENCODING));

        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        return null;
    }
}
