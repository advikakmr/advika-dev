+++
date = '2025-07-27T18:14:53-07:00'
draft = false
title = 'Model Context Protocol: An Overview'
desc = 'A comprehensive overview for developers in AI encountering MCP for the first time.'
image = '/images/mcp_logo.webp'
categories = ['AI', 'Python']
author = "Advika Kumar"
avatar = "/images/avatar.webp"
+++
#  What is MCP?

**Model Context Protocol** is the “USB-C” or the “glue” of agentic AI—a protocol developed by Anthropic to standardize how tools, resources, prompts, and more (i.e. context) are exposed to AI agents. Its name effectively describes its job:
- **Model** - the large language model used within the AI agent    
- **Context** - the preliminary information given to a model to produce output that is relevant and accurate to the needs of the developer    
- **Protocol** - the set of rules outlining how an agent can communicate with a server to receive necessary context; MCP creates a universal version of these rules     
    
#  Architecture

MCP can be broken down into three components: the host, the client, and the server. The **host** is the agent itself. It contains and manages the LLM application as well as the MCP client. The **client** is the implementation layer that creates the link between the host and the server via the Model Context Protocol. The **server** exposes the context that the host wishes to access. It accesses external local or remote data sources to extract the desired information.   


![MCP Flow](/images/mcp-flow.webp "MCP Flow")

Let’s dive deeper into the different types of context an MCP server can contain. **Tools** (required) are the highlight of MCP servers. They are essentially functions. They give an agent the ability to execute a specific action. Given a list of tools, an agent decides which tool would be most helpful to answer a user’s query. A regular method becomes an agentic tool through an annotation/wrapper that describes the tool with its name, parameters, functionality, and output schema (more on this later). **Resources** (optional) are the data sources stored on the server, like datasets or config files. They are similar to the GET endpoints of a REST API. **Prompts** (optional) are pre-defined templates designed to guide the output of an LLM. 

Here’s what an MCP server looks like in practice, using OpenAI's Agents SDK (Remember to export your API key!):

`server.py`
```python
from fastmcp import FastMCP

mcp = FastMCP("MCP Server")

@mcp.tool
async def do_something(
    arg1: str,
    arg2: int,
) -> str:
    """
    Description of the tool.
    
    :param arg1: Description of argument 1.
    :param arg2: Description of argument 2.
    :return: Description of the tool result.
    """
    return ""

if __name__ == "__main__":
    mcp.run()
```
`agent.py`
```python
from agents import Agent, Runner
from agents.mcp import MCPServerStdio
import asyncio, aioconsole

async def main():
    async with MCPServerStdio(
        name="Agent",
        params={
            "command": "python",
            "args": ["server.py"]
        }
    ) as server:
        agent = Agent(
            name="Agent",
            instructions="You are a helpful assistant.",
            mcp_servers=[server]
        )
        question = await aioconsole.ainput("Enter a question: ")
        result = await Runner.run(agent, question)
        print(result.final_output)

if __name__ == "__main__":
    asyncio.run(main())
```
Once the server is running, the agent will be able to connect and access all available tools.

#  Transport Types

MCP currently supports two transport types: **standard input/output (STDIO)** for local use cases and **streamable Hypertext Transfer Protocol (HTTP)** for remote servers. In servers running via STDIO, the MCP client will launch its own server subprocess, enabling direct 1:1 coupling as well as auto-cleanup. This option is recommended for when the client and server run within the same program. For remote HTTP transport, the MCP server is its own independent process, enabling multiple clients to connect to it. HTTP servers have a single /mcp endpoint supporting both GET and POST requests. 

There is also a third, deprecated transport method: server-sent events (SSE). SSE only allowed for one-way communication from the server to the client, and its stateful design limited scalability. Streamable HTTP solves these issues through its two-way communication and scalable nature due to its stateless architecture. The [Github MCP server](https://github.com/github/github-mcp-server) is an example of both local and remote transport methods.

#  Why MCP?

Before MCP, tool-integration was annoying. Every new tool added to an agent forced a developer to write their own custom implementation. If the developer wanted to reuse tools for different agents, copying this code across programs was difficult and redundant. Essentially, tool-calling was hard-wired and program-specific, which was not ideal for reusability and scalability. 

MCP solves this problem: rather than having developers create a new implementation of context-retrieval with every agentic workflow, MCP allows agents to simply connect to one server that contains all of the necessary context. Every tool implementation will now adhere to the same protocol, which means all MCP-compatible agents will follow similar workflows. Importantly, MCP decouples tool-calling from other capabilities of an AI agent. In other words, tools can easily be plugged in and out of a program, which also means community MCP servers can be created and shared.

# MCP vs APIs
MCP tools typically call REST APIs to carry out their functionality. The server is the translation or adaptation layer for the LLM, creating a standard way for the necessary APIs to be called. MCP does more than just wrap up APIs within a server; it extends and enhances their functionalities. For example, APIs are designed to handle single, one-step tasks. However, tools in an MCP server target broader problems, as a single tool can call many API endpoints to achieve its goal. Moreover, through MCP’s sampling feature, a server can prompt an LLM for an output as an intermediary step before sending back a final response to the client, effectively using AI to enhance the basic capabilities of an API. 
