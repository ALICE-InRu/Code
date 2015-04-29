<%@ Page Title="Apply models" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true"
    CodeBehind="Apply.aspx.cs" Inherits="ALICE.Apply" %>

<asp:Content ID="HeaderContent" runat="server" ContentPlaceHolderID="HeadContent">
</asp:Content>
<asp:Content ID="BodyContent" runat="server" ContentPlaceHolderID="MainContent">
<h2>
        Apply heuristics
    </h2>
    <p>
        Problem distribution:
        <asp:CheckBoxList ID="ApplyProblems" runat="server">
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
        <asp:CheckBoxList ID="ApplyDims" runat="server">
            <asp:ListItem>6x5</asp:ListItem>
            <asp:ListItem>10x10</asp:ListItem>
        </asp:CheckBoxList>
    </p>
    <p>
        Seta set:
        <asp:CheckBoxList ID="ApplySet" runat="server">
            <asp:ListItem>train</asp:ListItem>
            <asp:ListItem>test</asp:ListItem>
        </asp:CheckBoxList>
    </p>
    <p>
        <asp:Button ID="ApplyModel" runat="server" Text="Apply" 
            onclick="ApplyModel_Click" />
        <asp:Label ID="lblApplyModel" runat="server" Text=""></asp:Label>
    </p>
</asp:Content>
