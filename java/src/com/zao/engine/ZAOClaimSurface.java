package com.zao.engine;

public interface ZAOClaimSurface {
    boolean owns(Object body);

    String formOf(Object body);

    double performanceOf(Object body);
}
