return {
    -- get vim current mode, this information will be required by the provider
    -- and the highlight functions, so we compute it only once per component
    -- evaluation and store it as a component attribute
    init = function(self)
        self.mode = vim.fn.mode(1) -- :h mode()
    end,
    -- Now we define some dictionaries to map the output of mode() to the
    -- corresponding string and color. We can put these into `static` to compute
    -- them at initialisation time.
    static = {
        -- Nerd-font icons for every mode(1) output (see :help mode()).
        -- Ported from kyoh86/dotfiles (nvim/lua/kyoh86/plug/heirline/mode.lua).
        mode_icons = {
            n = "\u{E6AE}  ", --[[                   x : ノーマル ]]
            no = "\u{E6AE}\u{F01D8} ", --[[        󰇘 x : オペレータ待機 ]]
            nov = "\u{E6AE}\u{F01D8} ", --[[       󰇘 x : オペレータ待機（強制文字単位） ]]
            noV = "\u{E6AE}\u{F01D8} ", --[[       󰇘 x : オペレータ待機（強制行単位） ]]
            ["no\22"] = "\u{E6AE}\u{F01D8} ", --[[ 󰇘 x : オペレータ待機（強制ブロック単位） ]]
            niI = "\u{F246}\u{E6AE}", --[[         x : Insert-mode で i_CTRL-O を使用したノーマル ]]
            niR = "\u{F027C} \u{E6AE}", --[[       󰉼 x : Replace-mode で i_CTRL-O を使用したノーマル ]]
            niV = "\u{F027C} \u{E6AE}", --[[       󰉼 x : Virtual-Replace-mode で i_CTRL-O を使用したノーマル ]]
            nt = "\u{F120}\u{E6AE}", --[[          x : 端末ノーマル ]]

            v = "\u{F09A8}   ", --[[               󰦨   x : 文字単位ビジュアル ]]
            vs = "\u{F09A8}   ", --[[              󰦨   x : 選択モードで v_CTRL-O を利用した時の文字単位ビジュアル ]]
            V = "\u{F039}  ", --[[                   x : 行単位ビジュアル ]]
            Vs = "\u{F039}  ", --[[                  x : 選択モードで v_CTRL-O を利用した時の行単位ビジュアル ]]
            ["\22"] = "\u{F0FE6}   ", --[[          󰿦   x : 矩形ビジュアル ]]
            ["\22s"] = "\u{F0FE6}   ", --[[         󰿦   x : 選択モードで v_CTRL-O を利用した時の矩形ビジュアル ]]

            s = "\u{F45A}  ", --[[                   x : 文字単位選択 ]]
            S = "\u{F45A}  ", --[[                   x : 行単位選択 ]]
            ["\19"] = "\u{F45A}  ", --[[              x : 矩形選択 ]]

            i = "\u{F246}  ", --[[                   x : 挿入 ]]
            ic = "\u{F246}\u{F01D8} ", --[[        󰇘 x : 挿入モード補完 ]]
            ix = "\u{F246}\u{F01D8} ", --[[        󰇘 x : 挿入モード i_CTRL-X 補完 ]]

            R = "\u{F027C}   ", --[[               󰉼   x : 置換 ]]
            Rc = "\u{F027C} \u{F01D8} ", --[[      󰉼 󰇘 x : 置換モード補完 compl-generic ]]
            Rx = "\u{F027C} \u{F01D8} ", --[[      󰉼 󰇘 x : 置換モード i_CTRL-X 補完 ]]
            Rv = "\u{F027C}   ", --[[              󰉼   x : 仮想置換 gR ]]
            Rvc = "\u{F027C} \u{F01D8} ", --[[     󰉼 󰇘 x : 補完での仮想置換モード compl-generic ]]
            Rvx = "\u{F027C} \u{F01D8} ", --[[     󰉼 󰇘 x : i_CTRL-X 補完での仮想置換モード ]]

            c = "\u{F423}  ", --[[                   x : コマンドライン編集 ]]
            cv = "\u{F423}  ", --[[                  x : Vim Ex モード gO ]]
            ce = "\u{F423}  ", --[[                  x : ノーマル Ex モード Q ]]

            r = "\u{F071}  ", --[[                   x : 未使用（StatusLineが表示されない）; Hit-Enter プロンプト ]]
            rm = "\u{F071}  ", --[[                  x : 未使用（StatusLineが表示されない）; -- more -- プロンプト ]]
            ["r?"] = "\u{F059}  ", --[[              x : 未使用（StatusLineが表示されない）; ある種の :confirm 問い合わせ ]]

            t = "\u{F120}  ", --[[                   x : 端末モード ]]
            ["!"] = "\u{F070E}   ", --[[           󰜎   x : 未使用（StatusLineが表示されない）; シェルまたは外部コマンド実行中 ]]
        },
        -- NOTE: the mode color is inherited from the StatusLines `static`
        -- (see rvpm heirline hooks): `self:mode_color()`.
    },
    -- We can now access the value of mode() that, by now, would have been
    -- computed by `init()` and use it to index our icons dictionary.
    -- note how `static` fields become just regular attributes once the
    -- component is instantiated.
    provider = function(self)
        return "\u{00A0}" .. (self.mode_icons[self.mode] or "?")
    end,
    -- Same goes for the highlight. Now the background will change according to the current mode.
    -- (classic Airline style: mode-colored bg, black fg)
    -- The mode color is inherited from the StatusLines `static` (self:mode_color()).
    hl = function(self)
        return { bg = self:mode_color(), fg = "black", bold = true }
    end,
    -- Re-evaluate the component only on ModeChanged event!
    -- Also allows the statusline to be re-evaluated when entering operator-pending mode
    update = {
        "ModeChanged",
        pattern = "*:*",
        callback = vim.schedule_wrap(function()
            vim.cmd("redrawstatus")
        end),
    },
}
