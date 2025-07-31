+++
date = '2025-07-31T8:00:00-07:00'
draft = false
title = 'Model Context Protocol: An Overview'
desc = 'An introductory overview for developers in AI encountering MCP for the first time.'
image = '/images/mcp_logo.webp'
categories = ['AI', 'Python']
author = "Advika Kumar"
avatar = "/images/avatar.webp"
+++

Over the summer, I've been spending a lot of time working with the latest open framework for agentic AI: Model Context Protocol. In this article, we'll go through what exactly MCP is and how it can significantly enhance agentic workflows. 

#  What is MCP?

**Model Context Protocol** is the “USB-C” or the “glue” of agentic AI—a protocol developed by [Anthropic](https://www.anthropic.com/) to standardize how tools, resources, prompts, and more (i.e. context) are exposed to AI agents. Its name effectively describes its job:
- **Model** - the large language model used within the AI agent    
- **Context** - the preliminary information given to a model to produce output that is relevant and accurate to the needs of the developer    
- **Protocol** - the set of rules outlining how an agent can communicate with a server to receive necessary context; MCP creates a universal version of these rules     
    
#  Architecture

MCP can be broken down into three components: the host, the client, and the server. The **host** is the agent itself. It contains and manages the LLM application as well as the MCP client. The **client** is the implementation layer that creates the link between the host and the server via the Model Context Protocol. The **server** exposes the context that the host wishes to access. It accesses external local or remote data sources to extract the desired information.   

![MCP Flow](/images/mcp-flow.webp "MCP Flow")

Let’s dive deeper into the different types of context an MCP server can contain. **Tools** (required) are the highlight of MCP servers. They are essentially functions. They give an agent the ability to execute a specific action. Given a list of tools, an agent decides which tool would be most helpful to answer a user’s query. A regular method becomes an agentic tool through an annotation/wrapper that describes the tool with its name, parameters, functionality, and output schema (more on this later). **Resources** (optional) are the data sources stored on the server, like datasets or config files. They are similar to the GET endpoints of a REST API. **Prompts** (optional) are pre-defined templates designed to guide the output of an LLM. 

Here’s what a simple MCP server can look like in practice, using OpenAI's Agents SDK (remember to export your OpenAI API key!):

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
It's that simple! Once your server is up and running, the agent will be able to connect and access all available tools.

#  Transport Types

MCP currently supports two transport types. The first is **standard input/output (STDIO)** for local servers. With STDIO, the MCP client will launch its own server subprocess, enabling direct 1:1 coupling as well as auto-cleanup. This option is recommended for when the client and server run within the same program (see example above). 

The second transport type is **streamable Hypertext Transfer Protocol (HTTP)** for remote servers. In this case, the MCP server is its own independent process, enabling multiple clients to connect to it. This kind of server has a single /mcp endpoint, supporting both GET and POST HTTP requests. 

The [Github MCP server](https://github.com/github/github-mcp-server) is an example of both local and remote transport methods.

There is also a third, deprecated transport method: **server-sent events (SSE)**. SSE only allowed for one-way communication from the server to the client, and its stateful design limited scalability. Streamable HTTP solves these issues through its two-way communication and scalable nature due to its stateless architecture. 

#  Why MCP?

Before MCP, tool-integration was annoying. Every new tool added to an agent forced a developer to write their own custom implementation. If the developer wanted to reuse tools for different agents, copying this code across programs was difficult and redundant. Essentially, tool-calling was hard-wired and program-specific, which was not ideal for reusability and scalability. 

MCP solves this problem: rather than having developers create a new implementation of context-retrieval with every agentic workflow, MCP allows agents to simply connect to one server that contains all of the necessary context. Every tool implementation will now adhere to the same protocol, which means all MCP-compatible agents will follow similar workflows. Importantly, MCP decouples tool-calling from other capabilities of an AI agent. In other words, tools can easily be plugged in and out of a program, which also means community MCP servers can be created and shared.

Let's look at an example of how easily an MCP server can be plugged into a client. Say you have an MCP server running via STDIO, and you want to connect it to a client like [Claude Desktop](https://claude.ai/download). All it takes is editing the config files within the client to expose your server locally:    

`claude_desktop_config.json`
```json
{
    "mcpServers": {
        "your-mcp-server-name": {
            "command": "/Users/username/path/to/venv/bin/python",
            "args": "/Users/username/path/to/mcp-server.py"
        }
    }
}
```
The command is either the path to your virtual environment or simply "python". The argument is the path to your MCP server.    

*(Note: connecting remote HTTP servers to Claude Desktop requires a premium subscription.)*

# MCP vs APIs
MCP tools typically call REST APIs to carry out their functionality. The server acts as a kind of translation layer for the LLM, creating a standard way for agents to call the necessary APIs. However, MCP does more than just wrap up APIs within a server; it extends and enhances them. For instance, APIs are designed to handle single, one-step tasks. In contrast, tools in an MCP server target broader problems, as a single tool can call many API endpoints to achieve its goal. Moreover, through MCP’s sampling feature, a server can prompt an LLM for an output as an intermediary step before sending back a final response to the client, effectively using AI to enhance the basic capabilities of an API. Another benefit of MCP is its dynamic tool discovery. While API endpoints need to be documented and discovered in development, MCP tools are exposed and requested at runtime, making MCP servers much easier to scale.

# MCP & RAG
The capabilities of AI agents have always been limited by real-time access to information. In the beginning, all that an LLM could do was use the static information from its training to answer questions. As the world moved towards creating agents with human-like levels of decision-making and problem-solving, having access to external, up-to-date data was crucial. [Retrieval-Augmented Generation (RAG)](https://en.wikipedia.org/wiki/Retrieval-augmented_generation) attempted to combat this issue in 2024. Through RAG, models can reference large external knowledge bases to produce more useful and relevant outputs.       
       
MCP makes context retrieval incredibly simple through tool calling; as such, the protocol can be an effective wrapper for RAG. Moreover, agents can be powered by both systems, first calling RAG to gather information relevant to a user’s input, and then using an MCP server to carry out actions based on that information. There has been discussion on whether MCP will ultimately replace RAG, but I personally believe the two can work well together. They are similar frameworks but target different use-cases: RAG is primarily for informational queries, while MCP is designed to handle complex action-based scenarios.   

# Conclusion
Working so closely with MCP this summer has been exciting, and I'm eager to apply my new skills as I keep learning more about agentic AI. I hope this article has given you the fundamental knowledge you need to start using MCP yourself!