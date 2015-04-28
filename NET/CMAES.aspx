<%@ Page Title="Training data" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true"
    CodeFile="CMAES.aspx.cs" Inherits="About" %>

<asp:Content ID="HeaderContent" runat="server" ContentPlaceHolderID="HeadContent">
    <style type="text/css">
        #TextAreaOptimiseCMA
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
        CMA-ES OPTIMISATION
    </h2>
    <p>
        Problem distribution:
        <asp:CheckBoxList ID="CMAproblems" runat="server">
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
        <asp:CheckBoxList ID="CMAdims" runat="server">
            <asp:ListItem>6x5</asp:ListItem>
            <asp:ListItem>10x10</asp:ListItem>
        </asp:CheckBoxList>
    </p>
    <p>
        Objective function:
        <asp:CheckBoxList ID="CMAobjFun" runat="server">
            <asp:ListItem Value="MinimumMakespan">Minimum makespan</asp:ListItem>
            <asp:ListItem Value="MinimumRho">Minimum rho</asp:ListItem>
        </asp:CheckBoxList>
     </p>
    <p>
        <asp:Button ID="OptimiseCMA" runat="server" Text="Button" />
    </p>
    <p>
        <textarea id="TextAreaOptimiseCMA" name="S1" rows="10"></textarea>
    </p>
     
</asp:Content>
