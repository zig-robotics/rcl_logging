const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Specify static or dynamic linkage") orelse .dynamic;
    const upstream = b.dependency("rcl_logging", .{});
    const spdlog = b.dependency("spdlog", .{});
    var rcl_logging_interface = std.Build.Step.Compile.create(b, .{
        .root_module = .{
            .target = target,
            .optimize = optimize,
        },
        .name = "rcl_logging_interface",
        .kind = .lib,
        .linkage = linkage,
    });

    rcl_logging_interface.linkLibC();
    rcl_logging_interface.addIncludePath(upstream.path("rcl_logging_interface/include"));

    const rcutils_dep = b.dependency("rcutils", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });

    rcl_logging_interface.linkLibrary(rcutils_dep.artifact("rcutils"));

    rcl_logging_interface.addCSourceFiles(.{
        .root = upstream.path("rcl_logging_interface"),
        .files = &.{
            "src/logging_dir.c",
        },
    });

    rcl_logging_interface.installHeadersDirectory(
        upstream.path("rcl_logging_interface/include"),
        "",
        .{},
    );
    b.installArtifact(rcl_logging_interface);

    var rcl_logging_spdlog = std.Build.Step.Compile.create(b, .{
        .root_module = .{
            .target = target,
            .optimize = optimize,
        },
        .name = "rcl_logging_spdlog",
        .kind = .lib,
        .linkage = linkage,
    });

    rcl_logging_spdlog.linkLibCpp();
    rcl_logging_spdlog.addIncludePath(spdlog.path("include"));

    const rcpputils_dep = b.dependency("rcpputils", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });

    rcl_logging_spdlog.linkLibrary(rcl_logging_interface);
    rcl_logging_spdlog.linkLibrary(rcutils_dep.artifact("rcutils"));
    rcl_logging_spdlog.linkLibrary(rcpputils_dep.artifact("rcpputils"));

    rcl_logging_spdlog.addCSourceFiles(.{
        .root = upstream.path("rcl_logging_spdlog"),
        .files = &.{
            "src/rcl_logging_spdlog.cpp",
        },
        .flags = &[_][]const u8{
            "--std=c++17",
        },
    });

    b.installArtifact(rcl_logging_spdlog);
}
