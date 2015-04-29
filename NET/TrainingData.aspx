<%@ Page Title="Training data" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true"
    CodeFile="TrainingData.aspx.cs" Inherits="About" %>

<asp:Content ID="HeaderContent" runat="server" ContentPlaceHolderID="HeadContent">
    <style type="text/css">
        #TextAreaCreateTrdat
        {
            margin-left: 20px;
            margin-right: 20px;
            height: 100px;
            width: 880px;
        }
        #TextAreaCreatePrefSet
        {
            margin-left: 20px;
            margin-right: 20px;
            height: 100px;
            width: 880px;
        }
    </style>
</asp:Content>
<asp:Content ID="BodyContent" runat="server" ContentPlaceHolderID="MainContent">
    <h2>
        Training data
    </h2>
    <p>
        Problem distribution:
        <asp:CheckBoxList ID="TrdatProblems" runat="server">
            <asp:ListItem>j.rnd</asp:ListItem>
            <asp:ListItem>j.rndn</asp:ListItem>
            <asp:ListItem>f.rnd</asp:ListItem>
            <asp:ListItem>f.rndn</asp:ListItem>
            <asp:ListItem>f.jc</asp:ListItem>
            <asp:ListItem>f.mc</asp:ListItem>
            <asp:ListItem>f.mxc</asp:ListItem>
        </asp:CheckBoxList>
    </p>
    <p>
        Problem size:
        <asp:CheckBoxList ID="TrdatDims" runat="server">
            <asp:ListItem>6x5</asp:ListItem>
            <asp:ListItem>10x10</asp:ListItem>
        </asp:CheckBoxList>
    </p>
    <p>
        Trajectories:
        <asp:CheckBoxList ID="TrdatTracks" runat="server">
            <asp:ListItem>OPT</asp:ListItem>
            <asp:ListItem>SPT</asp:ListItem>
            <asp:ListItem>LPT</asp:ListItem>
            <asp:ListItem>LWR</asp:ListItem>
            <asp:ListItem>MWR</asp:ListItem>
            <asp:ListItem>CMA</asp:ListItem>
            <asp:ListItem>ILUNSUP</asp:ListItem>
            <asp:ListItem>ILSUP</asp:ListItem>
            <asp:ListItem>ILFIXSUP</asp:ListItem>
            <asp:ListItem>OPTGREEDY</asp:ListItem>
        </asp:CheckBoxList>
     </p>
     <p>
        Check if training set should be extended. For imitation learning each iteration explored new problem instances, otherwise <i>more</i> problem instances are collected.
        <asp:CheckBoxList ID="TrdatExtended" runat="server">
            <asp:ListItem Value="EXT">extended</asp:ListItem>
        </asp:CheckBoxList>
    </p>
    <p>
        <asp:Button ID="CreateLocalTrdat" runat="server" Text="Collect training set" 
            onclick="CreateLocalTrdat_Click" />
        <asp:Label ID="lblCreateLocalTrdat" runat="server" Text=""></asp:Label>
    </p>
    <p>
        <asp:Button ID="CreateGlobalTrdat" runat="server" Text="Collect global features"
            onclick="CreateGlobalTrdat_Click" />
        <asp:Label ID="lblCreateGlobalTrdat" runat="server" Text=""></asp:Label>
    </p>
    <p>
        <textarea id="TextAreaCreateTrdat" name="S1" rows="10" cols="20" 
            disabled="disabled"></textarea></p>
    <p>
        Ranking schemes:
        <asp:CheckBoxList ID="TrdatRanks" runat="server">
            <asp:ListItem Value="p">partial ranking</asp:ListItem>
            <asp:ListItem Value="f">full ranking</asp:ListItem>
            <asp:ListItem Value="b">base ranking</asp:ListItem>
            <asp:ListItem Value="a">all rankings</asp:ListItem>
        </asp:CheckBoxList>
    </p>
    <p>
        <asp:Button ID="CreatePrefSet" runat="server" Text="Collect preference set" 
            onclick="CreatePrefSet_Click" />
            <asp:Label ID="lblCreatePrefSet" runat="server" Text=""></asp:Label>
    </p>
    <p>
        <textarea id="TextAreaCreatePrefSet" name="S2" rows="10" cols="20" 
            disabled="disabled"></textarea>
    </p>    
</asp:Content>
