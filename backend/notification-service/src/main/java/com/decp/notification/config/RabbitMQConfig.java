package com.decp.notification.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    // Exchanges (matching what publisher services declare)
    public static final String USER_EXCHANGE = "user.exchange";
    public static final String POST_EXCHANGE = "post.exchange";
    public static final String EVENT_EXCHANGE = "event-exchange";
    public static final String JOB_EXCHANGE = "job.exchange";

    // Queues for notification service
    public static final String USER_REGISTERED_QUEUE = "notification.user.registered";
    public static final String POST_CREATED_QUEUE = "notification.post.created";
    public static final String POST_LIKED_QUEUE = "notification.post.liked";
    public static final String POST_COMMENTED_QUEUE = "notification.post.commented";
    public static final String JOB_CREATED_QUEUE = "notification.job.created";
    public static final String JOB_APPLIED_QUEUE = "notification.job.applied";
    public static final String EVENT_CREATED_QUEUE = "notification.event.created";
    public static final String EVENT_RSVP_QUEUE = "notification.event.rsvp";

    // Exchanges
    @Bean
    public TopicExchange userExchange() {
        return new TopicExchange(USER_EXCHANGE);
    }

    @Bean
    public TopicExchange postExchange() {
        return new TopicExchange(POST_EXCHANGE);
    }

    @Bean
    public TopicExchange eventExchange() {
        return new TopicExchange(EVENT_EXCHANGE);
    }

    @Bean
    public TopicExchange jobExchange() {
        return new TopicExchange(JOB_EXCHANGE);
    }

    // Queues
    @Bean
    public Queue userRegisteredQueue() {
        return new Queue(USER_REGISTERED_QUEUE, true);
    }

    @Bean
    public Queue postCreatedQueue() {
        return new Queue(POST_CREATED_QUEUE, true);
    }

    @Bean
    public Queue postLikedQueue() {
        return new Queue(POST_LIKED_QUEUE, true);
    }

    @Bean
    public Queue postCommentedQueue() {
        return new Queue(POST_COMMENTED_QUEUE, true);
    }

    @Bean
    public Queue jobCreatedQueue() {
        return new Queue(JOB_CREATED_QUEUE, true);
    }

    @Bean
    public Queue jobAppliedQueue() {
        return new Queue(JOB_APPLIED_QUEUE, true);
    }

    @Bean
    public Queue eventCreatedQueue() {
        return new Queue(EVENT_CREATED_QUEUE, true);
    }

    @Bean
    public Queue eventRsvpQueue() {
        return new Queue(EVENT_RSVP_QUEUE, true);
    }

    // Bindings
    @Bean
    public Binding userRegisteredBinding(Queue userRegisteredQueue, TopicExchange userExchange) {
        return BindingBuilder.bind(userRegisteredQueue).to(userExchange).with("user.registered");
    }

    @Bean
    public Binding postCreatedBinding(Queue postCreatedQueue, TopicExchange postExchange) {
        return BindingBuilder.bind(postCreatedQueue).to(postExchange).with("post.created");
    }

    @Bean
    public Binding postLikedBinding(Queue postLikedQueue, TopicExchange postExchange) {
        return BindingBuilder.bind(postLikedQueue).to(postExchange).with("post.liked");
    }

    @Bean
    public Binding postCommentedBinding(Queue postCommentedQueue, TopicExchange postExchange) {
        return BindingBuilder.bind(postCommentedQueue).to(postExchange).with("post.commented");
    }

    @Bean
    public Binding jobCreatedBinding(Queue jobCreatedQueue, TopicExchange jobExchange) {
        return BindingBuilder.bind(jobCreatedQueue).to(jobExchange).with("job.created");
    }

    @Bean
    public Binding jobAppliedBinding(Queue jobAppliedQueue, TopicExchange jobExchange) {
        return BindingBuilder.bind(jobAppliedQueue).to(jobExchange).with("job.applied");
    }

    @Bean
    public Binding eventCreatedBinding(Queue eventCreatedQueue, TopicExchange eventExchange) {
        return BindingBuilder.bind(eventCreatedQueue).to(eventExchange).with("event.created");
    }

    @Bean
    public Binding eventRsvpBinding(Queue eventRsvpQueue, TopicExchange eventExchange) {
        return BindingBuilder.bind(eventRsvpQueue).to(eventExchange).with("event.rsvp");
    }

    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}
