package com.mainzerdatenfabrik.main.logging.slack;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.mainzerdatenfabrik.main.logging.Logger;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;

import java.io.IOException;
import java.util.logging.Level;

/**
 * Implementation of a class to send instances of the "SlackMessage" class to a slack channel.
 */
public class Slack {

    // The general web hook url, generated on the application page of slack.
    private static final String WEB_HOOK_URL_GENERAL = "https://hooks.slack.com/services/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";

    // The general web hook url of the "why_investigator" channel, generated on the application page of the slack website.
    private static String webHookUrl;

    // Indicates if the WhyInvestigator should give frequent updates via slack. This can be toggled on/off
    // in the Config-File (controlConfig -> slackLogging -> true/false).
    private static boolean isActive = false;

    /**
     * Initializes the Slack class by setting the base webHookUrl and whether slack logging should be activated or not.
     *
     * @param webHookUrl the base webHookUrl (i.e., the url generated on the slack application website)
     * @param slackLoggingActive the flag if logging should be active or not
     */
    public static void initialize(String webHookUrl, boolean slackLoggingActive) {
        Slack.webHookUrl = webHookUrl;
        Slack.isActive = slackLoggingActive;
    }

    /**
     *
     */
    public static void setWebHookUrl(String webHookUrl) {
        Slack.webHookUrl = webHookUrl;
    }

    /**
     *
     */
    public static void setSlackLoggingActive(boolean isActive) {
        Slack.isActive = isActive;
    }

    /**
     * Sends a specific slack message to the slack channel specified  by the WEBHOOK_URL_GENERAL.
     *
     * @param message the specific message to send to slack
     */
    private static void sendMessage(SlackMessage message, String destinationURL) {
        try(CloseableHttpClient client = HttpClients.createDefault()) {
            HttpPost httpPost = new HttpPost(destinationURL);

            ObjectMapper objectMapper = new ObjectMapper();
            String json = objectMapper.writeValueAsString(message);

            StringEntity entity = new StringEntity(json);
            httpPost.setEntity(entity);
            httpPost.setHeader("Accept", "application/json");
            httpPost.setHeader("Content-type", "application/json");

            client.execute(httpPost);
        } catch (IOException e) {
            Logger.getLogger().severe("Exception occurred while sending slack message.");
            Logger.getLogger().log(Level.SEVERE, e.getMessage(), e);
        }
    }

    /**
     * Send a message to the slack channel specified by destinationURL, based on a specific text.
     *
     * @param text the text of the message (i.e., the message itself)
     */
    public static void sendMessageToDestination(String text, String destinationURL) {
        sendMessage(new SlackMessage(text), destinationURL);
    }

    /**
     * Sends a message to the default slack channel based on a specific text.
     *
     * @param text the text of the messsage (i.e., the message itself)
     */
    public static void sendMessage(String text) {
        sendMessage(new SlackMessage(text), WEB_HOOK_URL_GENERAL);
    }

    /**
     * Send a message to the slack channel specified by destinationURL, based on a specific
     * username and a specific text.
     *
     * @param username the name of the user sending the message
     * @param text the message itself
     */
    public static void sendMessageToDestination(String username, String text, String destinationURL) {
        sendMessage(new SlackMessage(username, text), destinationURL);
    }

    /**
     * Send a message to the default slack channel based on a specific username and a specific text.
     *
     * @param username the name of the user sending the message
     * @param text the message itself
     */
    public static void sendMessage(String username, String text) {
        sendMessage(new SlackMessage(username, text), WEB_HOOK_URL_GENERAL);
    }

    /**
     * Sends a message to the slack channel specified by the WEBHOOK_URL_GENERAL, based on a specific
     * username, message and emoji string
     *
     * @param username the name of the user sending the message
     * @param text the message itself
     * @param emoji the icon emoji for the message
     */
    public static void sendMessageToDestination(String username, String text, String emoji, String destinationURL) {
        sendMessage(new SlackMessage(username, text, emoji), destinationURL);
    }

    /**
     * Sends a message to the default slack channel  based on a specific username, message and emoji string
     *
     * @param username the name of the user sending the message
     * @param text the message itself
     * @param emoji the icon emoji for the message
     */
    public static void sendMessage(String username, String text, String emoji) {
        sendMessage(new SlackMessage(username, text, emoji), WEB_HOOK_URL_GENERAL);
    }
}
