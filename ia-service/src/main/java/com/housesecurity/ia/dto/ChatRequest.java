package com.housesecurity.ia.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

/**
 * Molde do JSON que enviamos para a Groq.
 * Campos vazios (null) simplesmente não são enviados.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ChatRequest(
        String model,
        List<Message> messages,
        double temperature,
        @JsonProperty("max_completion_tokens") int maxCompletionTokens,
        @JsonProperty("reasoning_effort") String reasoningEffort,
        @JsonProperty("reasoning_format") String reasoningFormat
) {

    public record Message(String role, Object content) {
    }
}