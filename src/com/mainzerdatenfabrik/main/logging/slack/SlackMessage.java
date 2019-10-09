package com.mainzerdatenfabrik.main.logging.slack;

import java.io.Serializable;

/**
 * Simple implementation of a slack message. The message consists of a username to display, the message itself and
 * an icon emoji for the message.
 */
public class SlackMessage implements Serializable {

    private String username;
    private String text;
    private String icon_emoji;

    /**
     *  The constructor.
     *
     * @param text the text of the message
     */
    SlackMessage(String text) {
        this.text = text;
    }

    /**
     * The constructor.
     *
     * @param username the name of the user sending the message
     * @param text the text of the message
     */
    SlackMessage(String username, String text) {
        this.username = username;
        this.text = text;
    }

    /**
     * The constructor.
     *
     * @param username the name of the user sending the message
     * @param text the text of the message
     * @param icon_emoji the emoji icon of the message
     */
    SlackMessage(String username, String text, String icon_emoji) {
        this.username = username;
        this.text = text;
        this.icon_emoji = icon_emoji;
    }

    /**
     *
     * @return the username specified for the slack message. null if no username was set
     */
    public String getUsername() {
        return username;
    }

    /**
     *
     * @param username the string to set the username of the message to
     */
    public void setUsername(String username) {
        this.username = username;
    }

    /**
     *
     * @return the text of the message
     */
    public String getText() {
        return text;
    }

    /**
     *
     * @param text the string to set the text of the message to
     */
    public void setText(String text) {
        this.text = text;
    }

    /**
     *
     * @return the emoji icon of the message. null if no emoji was set
     */
    public String getIcon_emoji() {
        return icon_emoji;
    }

    /**
     *
     * @param icon_emoji the string to set the emoji icon of the message to
     */
    public void setIcon_emoji(String icon_emoji) {
        this.icon_emoji = icon_emoji;
    }
}
