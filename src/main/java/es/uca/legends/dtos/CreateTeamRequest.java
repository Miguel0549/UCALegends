package es.uca.legends.dtos;

import lombok.Data;

@Data
public class CreateTeamRequest {
    private String name;
    private String tag;
    private String region;
}